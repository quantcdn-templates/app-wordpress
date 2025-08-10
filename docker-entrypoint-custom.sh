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
    
    # Pass through WORDPRESS_TABLE_PREFIX if set
    if [ -n "${WORDPRESS_TABLE_PREFIX:-}" ]; then
        echo "export WORDPRESS_TABLE_PREFIX='${WORDPRESS_TABLE_PREFIX}'" >> /tmp/wp-env.sh
        echo "export WORDPRESS_TABLE_PREFIX=\"${WORDPRESS_TABLE_PREFIX}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Preserved WORDPRESS_TABLE_PREFIX (${WORDPRESS_TABLE_PREFIX})"
    fi
    
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

# Ensure wp-config.php exists (similar to official entrypoint)
ensure_wp_config_exists() {
    # Check if we have WORDPRESS_ env vars and no wp-config.php
    wpEnvs=( "${!WORDPRESS_@}" )
    if [ ! -s /var/www/html/wp-config.php ] && [ "${#wpEnvs[@]}" -gt 0 ]; then
        for wpConfigDocker in \
            /var/www/html/wp-config-docker.php \
            /usr/src/wordpress/wp-config-docker.php \
        ; do
            if [ -s "$wpConfigDocker" ]; then
                log "No 'wp-config.php' found, creating from template with WORDPRESS_ variables"
                # Create wp-config.php with unique salts
                awk '
                    /put your unique phrase here/ {
                        cmd = "head -c1m /dev/urandom | sha1sum | cut -d\\  -f1"
                        cmd | getline str
                        close(cmd)
                        gsub("put your unique phrase here", str)
                    }
                    { print }
                ' "$wpConfigDocker" > /var/www/html/wp-config.php
                # Skip chown - www-data already has UID 1000 matching EFS
                # chown www-data:www-data /var/www/html/wp-config.php 2>/dev/null || true
                break
            fi
        done
    fi
}

# Inject Quant include into wp-config.php before wp-settings.php
inject_wp_config_dynamic_urls() {
    local wp_config="/var/www/html/wp-config.php"
    if [ ! -f "${wp_config}" ]; then
        log "wp-config.php not found; cannot inject Quant include"
        return 0
    fi

    log "Ensuring Quant include is required from wp-config.php"
    local include_line="require_once '/quant/quant-include.php';"
    # If any quant include already present, ensure it's absolute; otherwise insert
    if grep -Fq "quant/quant-include.php" "${wp_config}"; then
        if grep -Fq "__DIR__ . '/quant/quant-include.php'" "${wp_config}"; then
            sed -i "s~require_once __DIR__ . '/quant/quant-include.php';~${include_line}~" "${wp_config}"
            log "Rewrote Quant include to absolute /quant path in wp-config.php"
        else
            log "Quant include already present (absolute) in wp-config.php; skipping"
        fi
        return 0
    fi

    # Insert the include just before wp-settings.php require
    local tmp_new="${wp_config}.quanttmp"
    awk -v inc="${include_line}" 'BEGIN{inserted=0} {
        if (!inserted && $0 ~ /require_once.*wp-settings\.php/) {
            print inc;
            inserted=1;
        }
        print
    }' "${wp_config}" > "${tmp_new}" && mv "${tmp_new}" "${wp_config}"
    log "Quant include injected into wp-config.php"
}

# Main execution
main() {
    log "Starting WordPress initialization..."
    
    # Apply environment variable mappings first
    apply_env_mapping
    
    # Ensure mu-plugins are present in the mounted wp-content
    sync_mu_plugins

    # Ensure wp-config.php exists (create if needed like official entrypoint)
    ensure_wp_config_exists
    
    # Inject Quant include into wp-config.php
    inject_wp_config_dynamic_urls
    
    log "WordPress initialization complete"
    log "Starting WordPress with command: $*"
    
    # Call the original WordPress entrypoint
    exec docker-entrypoint.sh "$@"
}

# Run main function with all arguments
main "$@" 