#!/bin/bash

# WP-CLI Wrapper for Quant Cloud
# This wrapper ensures database environment variables are properly mapped
# when WP-CLI is run via exec/cron (which don't run entrypoints)

# Source the WordPress environment mapping script directly
# This ensures DB_* variables are mapped to WORDPRESS_* variables
if [ -f /quant-entrypoints.d/00-wordpress-env-mapping.sh ]; then
    source /quant-entrypoints.d/00-wordpress-env-mapping.sh
fi

# Execute WP-CLI with all passed arguments
exec php /usr/local/bin/wp-cli.phar "$@"