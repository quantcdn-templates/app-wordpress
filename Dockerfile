# Use the official WordPress image as base
FROM wordpress:latest

# Install system packages, WP-CLI, and configure sudo in consolidated layers (rarely changes)
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        sudo \
    && rm -rf /var/lib/apt/lists/* \
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
    && chmod +x /usr/local/bin/wp \
    && \
    # Configure sudo for www-data to run apache2-foreground as root
    echo 'www-data ALL=(root) NOPASSWD: /usr/local/bin/apache2-foreground-real' >> /etc/sudoers.d/wordpress \
    && chmod 0440 /etc/sudoers.d/wordpress \
    && \
    # Create a wrapper for apache2-foreground that runs it as root
    mv /usr/local/bin/apache2-foreground /usr/local/bin/apache2-foreground-real \
    && echo '#!/bin/bash' > /usr/local/bin/apache2-foreground \
    && echo 'exec sudo /usr/local/bin/apache2-foreground-real "$@"' >> /usr/local/bin/apache2-foreground \
    && chmod +x /usr/local/bin/apache2-foreground

# Copy custom entrypoint (changes occasionally)
COPY docker-entrypoint-custom.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Set working directory
WORKDIR /var/www/html

# Run as www-data by default (for EFS operations)
USER www-data

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"] 