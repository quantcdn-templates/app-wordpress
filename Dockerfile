# Use the official WordPress image as base (allows override for legacy PHP versions)
ARG BASE_IMAGE=wordpress:latest
FROM ${BASE_IMAGE}

# Remap www-data to UID/GID 1000 to match EFS access points
RUN groupmod -g 1000 www-data && \
    usermod -u 1000 -g 1000 www-data && \
    # Fix ownership of existing www-data files after UID/GID change
    find / -user 33 -exec chown www-data {} \; 2>/dev/null || true && \
    find / -group 33 -exec chgrp www-data {} \; 2>/dev/null || true && \
    # Fix Apache log directory permissions
    chown -R www-data:www-data /var/log/apache2 && \
    # Ensure Apache run directory exists and has correct permissions
    mkdir -p /var/run/apache2 && \
    chown -R www-data:www-data /var/run/apache2

# Install system packages, WP-CLI, and configure sudo in consolidated layers (rarely changes)
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        sudo \
        gosu \
    && rm -rf /var/lib/apt/lists/* \
    && \
    # Install missing PHP sockets extension (required for WordPress FTP functionality)
    docker-php-ext-install sockets \
    && \
    # Enable mod_remoteip for proper client IP handling
    a2enmod remoteip \
    && \
    # Add Quant-Client-IP header to existing remoteip configuration
    echo 'RemoteIPHeader Quant-Client-IP' >> /etc/apache2/conf-available/remoteip.conf \
    && a2enconf remoteip \
    && \
    # Install WP-CLI
    curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.11.0/utils/wp-completion.bash \
    && curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.11.0/wp-cli-2.11.0.phar -o /usr/local/bin/wp-cli.phar \
    && chmod +x /usr/local/bin/wp-cli.phar \
    && \
    # Create WP-CLI wrapper that sources environment variables
    echo '#!/bin/bash' > /usr/local/bin/wp \
    && echo 'if [ -f /tmp/wp-env.sh ]; then source /tmp/wp-env.sh; fi' >> /usr/local/bin/wp \
    && echo 'exec php /usr/local/bin/wp-cli.phar "$@"' >> /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Configure sudo for www-data to run apache2-foreground as root and modify Apache config
RUN echo 'www-data ALL=(root) NOPASSWD:SETENV: /usr/local/bin/apache2-foreground-real' >> /etc/sudoers.d/wordpress \
    && echo 'www-data ALL=(root) NOPASSWD: /usr/bin/tee -a /etc/apache2/envvars' >> /etc/sudoers.d/wordpress \
    && echo 'www-data ALL=(root) NOPASSWD: /usr/bin/touch /etc/apache2/envvars' >> /etc/sudoers.d/wordpress \
    && echo 'Defaults:www-data env_keep += "WORDPRESS_CONFIG_EXTRA WORDPRESS_DB_HOST WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD WORDPRESS_TABLE_PREFIX QUANT_SMTP_FROM QUANT_SMTP_FROM_NAME"' >> /etc/sudoers.d/wordpress \
    && chmod 0440 /etc/sudoers.d/wordpress

# Create a wrapper for apache2-foreground that runs it as root and preserves required env vars
RUN mv /usr/local/bin/apache2-foreground /usr/local/bin/apache2-foreground-real \
    && echo '#!/bin/bash' > /usr/local/bin/apache2-foreground \
    && echo 'exec sudo --preserve-env=WORDPRESS_CONFIG_EXTRA,WORDPRESS_DB_HOST,WORDPRESS_DB_NAME,WORDPRESS_DB_USER,WORDPRESS_DB_PASSWORD,WORDPRESS_TABLE_PREFIX,QUANT_SMTP_FROM,QUANT_SMTP_FROM_NAME /usr/local/bin/apache2-foreground-real "$@"' >> /usr/local/bin/apache2-foreground \
    && chmod +x /usr/local/bin/apache2-foreground

# Copy custom entrypoint (changes occasionally)
COPY docker-entrypoint-custom.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Include repository mu-plugins (synced into wp-content at runtime)
COPY mu-plugins/ /mu-plugins/

# Include Quant config include (synced into site root at runtime)
COPY quant/ /quant/
RUN chmod +x /quant/entrypoints.sh && \
    if [ -d /quant/entrypoints ]; then chmod +x /quant/entrypoints/*; fi

# Copy Quant PHP configuration files (allows users to add custom PHP configs)
COPY quant/php.ini.d/* /usr/local/etc/php/conf.d/

# Set working directory
WORKDIR /var/www/html

# Start as root for entrypoints, then switch to www-data
# (entrypoints.sh will use gosu to switch to www-data for the main application)

# Use Quant entrypoints as the main entrypoint
ENTRYPOINT ["/quant/entrypoints.sh", "/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"] 
