#!/bin/bash
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

log "Running Quant post-WordPress setup..."

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

# Install and activate plugins defined in QUANT_PLUGINS (comma/space separated).
# Supports WordPress.org slugs (e.g., "akismet quant").
# Assumes wp-cli is available in the image.
install_and_activate_plugins() {
    if [ -z "${QUANT_PLUGINS:-}" ]; then
        return 0
    fi

    if ! command -v wp >/dev/null 2>&1; then
        log "wp-cli not found; skipping QUANT_PLUGINS installation"
        return 0
    fi

    # Only proceed after WordPress is fully installed
    if ! wp core is-installed --allow-root >/dev/null 2>&1; then
        log "WordPress is not installed yet; skipping QUANT_PLUGINS install/activation for now"
        return 0
    fi
    
    # Normalize list (commas/spaces -> single spaced list)
    normalized_plugins=$(echo "${QUANT_PLUGINS}" | tr ',' ' ' | xargs -n1 echo | sed '/^\s*$/d' | xargs)
    if [ -z "${normalized_plugins}" ]; then
        log "QUANT_PLUGINS is empty after normalization; skipping"
        return 0
    fi

    # Ensure DB is reachable (avoid TLS verification issue locally)
    if ! wp db check --allow-root -- --ssl-mode=DISABLED >/dev/null 2>&1; then
        log "Database not reachable yet; skipping plugin install/activation"
        return 0
    fi

    log "Installing/activating plugins: ${normalized_plugins}"
    if ! wp plugin install ${normalized_plugins} --activate --force --allow-root; then
        log "Bulk install failed; attempting per-plugin install"
        for plugin in ${normalized_plugins}; do
            wp plugin install "${plugin}" --activate --force --allow-root || log "Failed to install/activate: ${plugin}"
        done
    fi
}

# Run Quant post-WordPress setup
sync_mu_plugins
inject_wp_config_dynamic_urls
install_and_activate_plugins

log "Quant post-WordPress setup complete. Starting: $*"

# Start the final command (usually Apache)
exec "$@"
