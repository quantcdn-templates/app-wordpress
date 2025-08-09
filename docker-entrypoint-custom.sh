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
    
    # Create/append to Apache environment file (need sudo since we run as www-data)
    sudo touch /etc/apache2/envvars
    
    # Map Quant Cloud DB variables to WordPress variables if they exist
    if [ -n "${DB_HOST:-}" ]; then
        if [ -n "${DB_PORT:-}" ] && [ "${DB_PORT}" != "3306" ]; then
            export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT}"
            echo "export WORDPRESS_DB_HOST='${DB_HOST}:${DB_PORT}'" >> /tmp/wp-env.sh
            echo "export WORDPRESS_DB_HOST=\"${DB_HOST}:${DB_PORT}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        else
            export WORDPRESS_DB_HOST="${DB_HOST}"
            echo "export WORDPRESS_DB_HOST='${DB_HOST}'" >> /tmp/wp-env.sh
            echo "export WORDPRESS_DB_HOST=\"${DB_HOST}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        fi
        log "Mapped DB_HOST (${DB_HOST}) to WORDPRESS_DB_HOST"
    fi
    
    if [ -n "${DB_DATABASE:-}" ]; then
        export WORDPRESS_DB_NAME="${DB_DATABASE}"
        echo "export WORDPRESS_DB_NAME='${DB_DATABASE}'" >> /tmp/wp-env.sh
        echo "export WORDPRESS_DB_NAME=\"${DB_DATABASE}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped DB_DATABASE (${DB_DATABASE}) to WORDPRESS_DB_NAME"
    fi
    
    if [ -n "${DB_USERNAME:-}" ]; then
        export WORDPRESS_DB_USER="${DB_USERNAME}"
        echo "export WORDPRESS_DB_USER='${DB_USERNAME}'" >> /tmp/wp-env.sh
        echo "export WORDPRESS_DB_USER=\"${DB_USERNAME}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped DB_USERNAME to WORDPRESS_DB_USER"
    fi
    
    if [ -n "${DB_PASSWORD:-}" ]; then
        export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
        echo "export WORDPRESS_DB_PASSWORD='${DB_PASSWORD}'" >> /tmp/wp-env.sh
        echo "export WORDPRESS_DB_PASSWORD=\"${DB_PASSWORD}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped DB_PASSWORD to WORDPRESS_DB_PASSWORD"
    fi
    
    # No longer support WP_CONFIG_EXTRA/WORDPRESS_CONFIG_EXTRA; mu-plugins handles dynamic URLs
    
    chmod +x /tmp/wp-env.sh
    log "Environment variable mapping complete"
    log "WordPress environment variables written to Apache envvars"
}

# Sync repository-provided mu-plugins into the EFS-mounted wp-content on each start
sync_mu_plugins() {
    local source_dir="/mu-plugins"
    local target_dir="/var/www/html/wp-content/mu-plugins"
    if [ -d "${source_dir}" ]; then
        log "Syncing mu-plugins from ${source_dir} to ${target_dir}..."
        mkdir -p "${target_dir}"
        if command -v rsync >/dev/null 2>&1; then
            rsync -a "${source_dir}/" "${target_dir}/"
        else
            cp -r "${source_dir}/." "${target_dir}/" || true
        fi
        log "mu-plugins sync complete"
    else
        log "No mu-plugins directory found at ${source_dir}; skipping sync"
    fi
}

# Main execution
main() {
    log "Starting WordPress initialization..."
    
    # Apply environment variable mappings first
    apply_env_mapping
    
    # Ensure mu-plugins are present in the mounted wp-content
    sync_mu_plugins
    
    log "WordPress initialization complete"
    log "Starting WordPress with command: $*"
    
    # Call the original WordPress entrypoint
    exec docker-entrypoint.sh "$@"
}

# Run main function with all arguments
main "$@" 