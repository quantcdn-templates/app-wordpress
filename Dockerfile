# Copy WordPress entrypoint files from official image
ARG PHP_VERSION=8.4
FROM wordpress:php${PHP_VERSION}-apache AS wordpress-official

# Use our secure app-apache-php base image instead of vulnerable WordPress base
FROM ghcr.io/quantcdn-templates/app-apache-php:${PHP_VERSION}

# Install WordPress-specific dependencies not in our base image
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        # Ghostscript is required for rendering PDF previews
        ghostscript \
        # Additional dev libraries for WordPress-specific PHP extensions
        libavif-dev \
        libicu-dev \
        libmagickwand-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install WordPress-specific PHP extensions not in our base image
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libavif-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libwebp-dev \
		libzip-dev \
	; \
	\
	# Reconfigure GD with AVIF support (our base has basic GD)
	docker-php-ext-configure gd \
		--with-avif \
		--with-freetype \
		--with-jpeg \
		--with-webp \
	; \
	docker-php-ext-install -j "$(nproc)" \
		exif \
		intl \
		mysqli \
	; \
	# Install ImageMagick extension
	pecl install imagick-3.8.0; \
	docker-php-ext-enable imagick; \
	rm -r /tmp/pear; \
	\
	# Verify extensions work correctly
	out="$(php -r 'exit(0);')"; \
	[ -z "$out" ]; \
	err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
	[ -z "$err" ]; \
	\
	extDir="$(php -r 'echo ini_get("extension_dir");')"; \
	[ -d "$extDir" ]; \
	# Clean up build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$extDir"/*.so \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
	! { ldd "$extDir"/*.so | grep 'not found'; }; \
	# Check for PHP extension loading errors
	err="$(php --version 3>&1 1>&2 2>&3)"; \
	[ -z "$err" ]

# WordPress-specific PHP configuration (in addition to our base config)
RUN { \
    # WordPress-specific opcache settings (override our base config)
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
} > /usr/local/etc/php/conf.d/opcache-wordpress.ini

# WordPress-specific error logging configuration
RUN { \
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'ignore_repeated_source = Off'; \
    echo 'html_errors = Off'; \
} > /usr/local/etc/php/conf.d/error-logging.ini

# WordPress-specific Apache configuration
RUN set -eux; \
    a2enmod expires; \
    \
    # Note: Quant-Client-IP RemoteIPHeader already configured in base image
    \
    # Fix LogFormat for proper client IP logging
    find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +

# Copy WordPress source files from official image (instead of manually downloading)
COPY --from=wordpress-official --chown=www-data:www-data /usr/src/wordpress /usr/src/wordpress
# Copy pre-created wp-content structure from official image  
COPY --from=wordpress-official --chown=www-data:www-data /var/www/html/wp-content /var/www/html/wp-content

# Fix Apache log directory permissions (UID/GID already handled by base image)
RUN chown -R www-data:www-data /var/log/apache2

# Install WP-CLI (system packages and PHP extensions already handled by base image)
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.11.0/utils/wp-completion.bash \
    && curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.11.0/wp-cli-2.11.0.phar -o /usr/local/bin/wp-cli.phar \
    && chmod +x /usr/local/bin/wp-cli.phar \
    && \
    # Create WP-CLI wrapper that sources environment variables
    echo '#!/bin/bash' > /usr/local/bin/wp \
    && echo 'if [ -f /tmp/wp-env.sh ]; then source /tmp/wp-env.sh; fi' >> /usr/local/bin/wp \
    && echo 'exec php /usr/local/bin/wp-cli.phar "$@"' >> /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Note: Quant Host header override already configured in base image

# Include repository mu-plugins (synced into wp-content at runtime)
COPY mu-plugins/ /mu-plugins/

# Include Quant config include (synced into site root at runtime)
COPY quant/ /quant/
RUN chmod +x /quant/entrypoints.sh && \
    if [ -d /quant/entrypoints ]; then chmod +x /quant/entrypoints/*; fi

# Copy Quant PHP configuration files (allows users to add custom PHP configs)
COPY quant/php.ini.d/* /usr/local/etc/php/conf.d/

# Create volume mount point (mirroring official WordPress image)
VOLUME /var/www/html

# Copy WordPress files from official image
COPY --from=wordpress-official --chown=www-data:www-data /usr/src/wordpress/wp-config-docker.php /usr/src/wordpress/
COPY --from=wordpress-official /usr/local/bin/docker-entrypoint.sh /usr/local/bin/

# Copy Quant post-WordPress setup script
COPY quant-post-wordpress-setup.sh /usr/local/bin/
COPY apache2-foreground-wrapper.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/quant-post-wordpress-setup.sh /usr/local/bin/apache2-foreground-wrapper.sh

# No need to replace apache2-foreground, we'll use CMD to call our wrapper

# Create docker-ensure-installed.sh symlink (https://github.com/docker-library/wordpress/issues/969)
RUN ln -svfT docker-entrypoint.sh /usr/local/bin/docker-ensure-installed.sh

# Clear document root so WordPress entrypoint can detect empty directory
RUN rm -rf /var/www/html/* /var/www/html/.*  2>/dev/null || true

# Set working directory
WORKDIR /var/www/html

# Use Quant entrypoints -> Official WordPress entrypoint -> Custom Quant setup -> Apache
ENTRYPOINT ["/quant/entrypoints.sh", "docker-entrypoint.sh"]
CMD ["apache2-foreground-wrapper.sh"] 
