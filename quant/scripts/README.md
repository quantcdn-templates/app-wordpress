# Quant Scripts Directory

This directory contains utility scripts used by the WordPress container.

## Scripts

### `wp-cli-wrapper.sh`
WP-CLI wrapper that ensures database environment variables are properly mapped when WP-CLI is executed via `docker exec` or cron jobs (which don't run entrypoints).

**How it works:**
- Sources `/quant-entrypoints.d/00-wordpress-env-mapping.sh` directly
- Maps `DB_*` environment variables to `WORDPRESS_*` variables
- Executes WP-CLI with all passed arguments

**Installed as:** `/usr/local/bin/wp`

### `quant-post-wordpress-setup.sh`
Post-WordPress setup script that syncs Quant-specific files and configurations after WordPress initialization.

**How it works:**
- Syncs mu-plugins from `/mu-plugins/` to `/var/www/html/wp-content/mu-plugins/`
- Syncs Quant configuration files
- Applies WordPress-specific Quant integrations

**Installed as:** `/usr/local/bin/quant-post-wordpress-setup.sh`

### `apache2-foreground-wrapper.sh`
Apache startup wrapper that runs the Quant post-WordPress setup script after the official WordPress entrypoint completes.

**How it works:**
- Executes `quant-post-wordpress-setup.sh` (syncs mu-plugins, applies configurations)
- Starts Apache in foreground mode

**Installed as:** `/usr/local/bin/apache2-foreground-wrapper.sh`

## Organization

Scripts are organized here instead of being scattered in the repository root or generated inline in the Dockerfile. This provides:

- **Better maintainability**: Scripts can be edited as proper files
- **Version control**: Changes to scripts are easily tracked
- **Testing**: Scripts can be tested independently
- **Clarity**: Clear separation of concerns and file organization