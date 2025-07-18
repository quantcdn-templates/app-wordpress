FROM wordpress:latest

# Install additional utilities needed for health checks and database connectivity
RUN apt-get update && apt-get install -y \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Copy custom entrypoint
COPY docker-entrypoint-custom.sh /usr/local/bin/

# Make the custom entrypoint executable
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Set working directory
WORKDIR /var/www/html

# Expose port 80
EXPOSE 80

# Use custom entrypoint that handles environment variable mapping
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"] 