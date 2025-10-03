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
# Supports WordPress.org slugs (e.g., "quant akismet") and direct ZIP URLs.
install_and_activate_plugins() {
    if [ -z "${QUANT_PLUGINS:-}" ]; then
        return 0
    fi

    # Ensure wp-cli is available
    local have_wp_cli=0
    if command -v wp >/dev/null 2>&1; then
        have_wp_cli=1
    fi

    log "Processing QUANT_PLUGINS: ${QUANT_PLUGINS}"
    local plugins_dir="/var/www/html/wp-content/plugins"
    mkdir -p "${plugins_dir}"

    echo "${QUANT_PLUGINS}" \
      | tr ',' ' ' \
      | xargs -n1 echo \
      | sed '/^\s*$/d' \
      | while read -r item; do
            # If item looks like a URL (contains ://) or ends with .zip, install from URL
            if echo "$item" | grep -Eq '://|\.zip$'; then
                log "Installing plugin from URL: $item"
                if [ "$have_wp_cli" -eq 1 ]; then
                    wp plugin install "$item" --activate --allow-root || log "Failed to install from URL via wp-cli: $item"
                else
                    # Fallback: manual download and extract
                    tmp_zip="$(mktemp /tmp/plugin.XXXXXX.zip)"
                    if curl -fsSL "$item" -o "$tmp_zip"; then
                        unzip -o -q "$tmp_zip" -d "$plugins_dir" || log "Failed to unzip plugin: $item"
                        rm -f "$tmp_zip"
                        chown -R www-data:www-data "$plugins_dir" || true
                        # Try to activate if wp-cli is present later in loop
                    else
                        log "Failed to download plugin URL: $item"
                    fi
                fi
                continue
            fi

            # Otherwise treat as a WordPress.org slug
            local slug="$item"
            if [ "$have_wp_cli" -eq 1 ]; then
                if wp plugin is-installed "$slug" --allow-root; then
                    log "Activating installed plugin: $slug"
                    wp plugin activate "$slug" --allow-root || log "Failed to activate: $slug"
                else
                    log "Installing and activating plugin: $slug"
                    if ! wp plugin install "$slug" --activate --allow-root; then
                        log "wp-cli install failed for $slug; attempting manual download"
                        url="https://downloads.wordpress.org/plugin/${slug}.zip"
                        tmp_zip="$(mktemp /tmp/plugin.XXXXXX.zip)"
                        if curl -fsSL "$url" -o "$tmp_zip"; then
                            unzip -o -q "$tmp_zip" -d "$plugins_dir" || log "Failed to unzip plugin: $slug"
                            rm -f "$tmp_zip"
                            chown -R www-data:www-data "$plugins_dir" || true
                            wp plugin activate "$slug" --allow-root || log "Failed to activate after manual install: $slug"
                        else
                            log "Failed to download from $url"
                        fi
                    fi
                fi
            else
                # No wp-cli: attempt manual install, activation will be skipped
                url="https://downloads.wordpress.org/plugin/${slug}.zip"
                log "wp-cli not available; downloading $slug from $url"
                tmp_zip="$(mktemp /tmp/plugin.XXXXXX.zip)"
                if curl -fsSL "$url" -o "$tmp_zip"; then
                    unzip -o -q "$tmp_zip" -d "$plugins_dir" || log "Failed to unzip plugin: $slug"
                    rm -f "$tmp_zip"
                    chown -R www-data:www-data "$plugins_dir" || true
                    log "Installed $slug (activation skipped without wp-cli)"
                else
                    log "Failed to download from $url"
                fi
            fi
        done
}

# Run Quant post-WordPress setup
sync_mu_plugins
inject_wp_config_dynamic_urls
install_and_activate_plugins

log "Quant post-WordPress setup complete. Starting: $*"

# Start the final command (usually Apache)
exec "$@"
