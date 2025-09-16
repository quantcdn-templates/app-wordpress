# Copy WordPress entrypoint files from official image
ARG PHP_VERSION=8.4
ARG WORDPRESS_PHP_VERSION=${PHP_VERSION}
FROM wordpress:php${WORDPRESS_PHP_VERSION}-apache AS wordpress-official

# Use our secure app-apache-php base image instead of vulnerable WordPress base
FROM ghcr.io/quantcdn-templates/app-apache-php:${PHP_VERSION}

# Always remove the default content provided by the base image.
RUN rm -rf /var/www/html/* /var/www/html/.*  2>/dev/null || true

# Copy WordPress source files from official image (instead of manually downloading)
COPY --from=wordpress-official --chown=www-data:www-data /usr/src/wordpress /usr/src/wordpress
# Copy pre-created wp-content structure from official image  
COPY --from=wordpress-official --chown=www-data:www-data /var/www/html/wp-content /var/www/html/wp-content

# Install WP-CLI (system packages and PHP extensions already handled by base image)
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.11.0/utils/wp-completion.bash \
    && curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.11.0/wp-cli-2.11.0.phar -o /usr/local/bin/wp-cli.phar \
    && chmod +x /usr/local/bin/wp-cli.phar

# Copy WP-CLI wrapper script that sources environment mapping directly
COPY quant/scripts/wp-cli-wrapper.sh /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

# Include repository mu-plugins (synced into wp-content at runtime)
COPY mu-plugins/ /mu-plugins/

# Include Quant config include (synced into site root at runtime)
COPY quant/quant-include.php /quant/

# Copy custom entrypoint scripts to Quant platform location (if any exist)
COPY quant/entrypoints/ /quant-entrypoint.d/
RUN if [ "$(ls -A /quant-entrypoint.d/)" ]; then chmod +x /quant-entrypoint.d/*; fi

# Copy custom PHP configuration files (if any exist)
COPY quant/php.ini.d/ /usr/local/etc/php/conf.d/

# Create volume mount point (mirroring official WordPress image)
VOLUME /var/www/html

# Copy WordPress files from official image
COPY --from=wordpress-official --chown=www-data:www-data /usr/src/wordpress/wp-config-docker.php /usr/src/wordpress/
COPY --from=wordpress-official /usr/local/bin/docker-entrypoint.sh /usr/local/bin/

# Copy Quant scripts
COPY quant/scripts/quant-post-wordpress-setup.sh /usr/local/bin/
COPY quant/scripts/apache2-foreground-wrapper.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/quant-post-wordpress-setup.sh /usr/local/bin/apache2-foreground-wrapper.sh

# Create docker-ensure-installed.sh symlink (https://github.com/docker-library/wordpress/issues/969)
RUN ln -svfT docker-entrypoint.sh /usr/local/bin/docker-ensure-installed.sh

# Clear document root so WordPress entrypoint can detect empty directory
RUN rm -rf /var/www/html/* /var/www/html/.*  2>/dev/null || true

# Use Official WordPress entrypoint -> Custom Quant setup -> Apache
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground-wrapper.sh"] 
