#!/bin/bash
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to apply environment variable mappings
apply_env_mapping() {
    log "Applying Quant Cloud environment variable mappings..."
    
    # Create environment file for WP-CLI
    echo "#!/bin/bash" > /tmp/wp-env.sh
    
    # Map Quant Cloud DB variables to WordPress variables if they exist
    if [ -n "${DB_HOST:-}" ]; then
        if [ -n "${DB_PORT:-}" ] && [ "${DB_PORT}" != "3306" ]; then
            export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT}"
            echo "export WORDPRESS_DB_HOST='${DB_HOST}:${DB_PORT}'" >> /tmp/wp-env.sh
            echo "WORDPRESS_DB_HOST=${DB_HOST}:${DB_PORT}" >> /etc/environment
        else
            export WORDPRESS_DB_HOST="${DB_HOST}"
            echo "export WORDPRESS_DB_HOST='${DB_HOST}'" >> /tmp/wp-env.sh
            echo "WORDPRESS_DB_HOST=${DB_HOST}" >> /etc/environment
        fi
        log "Mapped DB_HOST (${DB_HOST}) to WORDPRESS_DB_HOST"
    fi
    
    if [ -n "${DB_DATABASE:-}" ]; then
        export WORDPRESS_DB_NAME="${DB_DATABASE}"
        echo "export WORDPRESS_DB_NAME='${DB_DATABASE}'" >> /tmp/wp-env.sh
        echo "WORDPRESS_DB_NAME=${DB_DATABASE}" >> /etc/environment
        log "Mapped DB_DATABASE (${DB_DATABASE}) to WORDPRESS_DB_NAME"
    fi
    
    if [ -n "${DB_USERNAME:-}" ]; then
        export WORDPRESS_DB_USER="${DB_USERNAME}"
        echo "export WORDPRESS_DB_USER='${DB_USERNAME}'" >> /tmp/wp-env.sh
        echo "WORDPRESS_DB_USER=${DB_USERNAME}" >> /etc/environment
        log "Mapped DB_USERNAME to WORDPRESS_DB_USER"
    fi
    
    if [ -n "${DB_PASSWORD:-}" ]; then
        export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
        echo "export WORDPRESS_DB_PASSWORD='${DB_PASSWORD}'" >> /tmp/wp-env.sh
        echo "WORDPRESS_DB_PASSWORD=${DB_PASSWORD}" >> /etc/environment
        log "Mapped DB_PASSWORD to WORDPRESS_DB_PASSWORD"
    fi
    
    if [ -n "${WP_CONFIG_EXTRA:-}" ]; then
        export WORDPRESS_CONFIG_EXTRA="${WP_CONFIG_EXTRA}"
        echo "export WORDPRESS_CONFIG_EXTRA='${WP_CONFIG_EXTRA}'" >> /tmp/wp-env.sh
        echo "WORDPRESS_CONFIG_EXTRA=${WP_CONFIG_EXTRA}" >> /etc/environment
        log "Mapped WP_CONFIG_EXTRA to WORDPRESS_CONFIG_EXTRA"
    fi
    
    chmod +x /tmp/wp-env.sh
    log "Environment variable mapping complete"
    log "WordPress environment variables written to /etc/environment"
}

# Main execution
main() {
    log "Starting WordPress initialization..."
    
    # Apply environment variable mappings first
    apply_env_mapping
    
    log "WordPress initialization complete"
    log "Starting WordPress with command: $*"
    
    # Call the original WordPress entrypoint with environment variables
    exec docker-entrypoint.sh "$@"
}

# Run main function with all arguments
main "$@" 