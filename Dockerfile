FROM wordpress:latest

# Install additional utilities needed for health checks and database connectivity
RUN apt-get update && apt-get install -y \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -o wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli.phar \
    && echo '#!/bin/bash' > /usr/local/bin/wp \
    && echo 'source /tmp/wp-env.sh 2>/dev/null || true' >> /usr/local/bin/wp \
    && echo 'exec php /usr/local/bin/wp-cli.phar "$@"' >> /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Copy custom entrypoint
COPY docker-entrypoint-custom.sh /usr/local/bin/

# Make the custom entrypoint executable
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Set working directory
WORKDIR /var/www/html

# Run as www-data
USER www-data

# Expose port 80
EXPOSE 80

# Use custom entrypoint that handles environment variable mapping
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"] 