#!/bin/bash
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to wait for database
wait_for_db() {
    local db_host="${DB_HOST:-${WORDPRESS_DB_HOST:-db}}"
    local db_port="${DB_PORT:-3306}"
    
    # Handle host:port format
    if [[ "$db_host" == *":"* ]]; then
        db_port="${db_host##*:}"
        db_host="${db_host%%:*}"
    fi
    
    log "Waiting for database at $db_host:$db_port..."
    
    while ! nc -z "$db_host" "$db_port" 2>/dev/null; do
        log "Database not ready, waiting..."
        sleep 2
    done
    
    log "Database is ready!"
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
        else
            export WORDPRESS_DB_HOST="${DB_HOST}"
            echo "export WORDPRESS_DB_HOST='${DB_HOST}'" >> /tmp/wp-env.sh
        fi
        log "Mapped DB_HOST (${DB_HOST}) to WORDPRESS_DB_HOST"
    fi
    
    if [ -n "${DB_DATABASE:-}" ]; then
        export WORDPRESS_DB_NAME="${DB_DATABASE}"
        echo "export WORDPRESS_DB_NAME='${DB_DATABASE}'" >> /tmp/wp-env.sh
        log "Mapped DB_DATABASE (${DB_DATABASE}) to WORDPRESS_DB_NAME"
    fi
    
    if [ -n "${DB_USERNAME:-}" ]; then
        export WORDPRESS_DB_USER="${DB_USERNAME}"
        echo "export WORDPRESS_DB_USER='${DB_USERNAME}'" >> /tmp/wp-env.sh
        log "Mapped DB_USERNAME to WORDPRESS_DB_USER"
    fi
    
    if [ -n "${DB_PASSWORD:-}" ]; then
        export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
        echo "export WORDPRESS_DB_PASSWORD='${DB_PASSWORD}'" >> /tmp/wp-env.sh
        log "Mapped DB_PASSWORD to WORDPRESS_DB_PASSWORD"
    fi
    
    if [ -n "${WP_CONFIG_EXTRA:-}" ]; then
        export WORDPRESS_CONFIG_EXTRA="${WP_CONFIG_EXTRA}"
        echo "export WORDPRESS_CONFIG_EXTRA='${WP_CONFIG_EXTRA}'" >> /tmp/wp-env.sh
        log "Mapped WP_CONFIG_EXTRA to WORDPRESS_CONFIG_EXTRA"
    fi
    
    chmod +x /tmp/wp-env.sh
    log "Environment variable mapping complete"
}

# Main execution
main() {
    log "Starting WordPress initialization..."
    
    # Apply environment variable mappings first
    apply_env_mapping
    
    # Wait for database if configured
    if [ -n "${DB_HOST:-${WORDPRESS_DB_HOST:-}}" ]; then
        wait_for_db
    fi
    
    log "WordPress initialization complete"
    log "Starting WordPress with command: $*"
    
    # Call the original WordPress entrypoint
    exec docker-entrypoint.sh "$@"
}

# Run main function with all arguments
main "$@" 