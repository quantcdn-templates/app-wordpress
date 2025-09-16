#!/bin/bash

# Docker Entrypoint Wrapper for Quant Cloud
# Sources environment mapping BEFORE calling WordPress entrypoint
# This ensures WORDPRESS_* variables are available when WordPress entrypoint runs

set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Docker Entrypoint Wrapper: Starting..." >&2

# Source the environment mapping script to export WORDPRESS_* variables
if [ -f /quant-entrypoint.d/00-wordpress-env-mapping.sh ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Docker Entrypoint Wrapper: Sourcing environment mapping..." >&2
    source /quant-entrypoint.d/00-wordpress-env-mapping.sh
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Docker Entrypoint Wrapper: Environment mapping script not found - WordPress entrypoint will use existing env vars" >&2
fi

# Now call the WordPress entrypoint with all original arguments
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Docker Entrypoint Wrapper: Calling WordPress entrypoint..." >&2
exec /usr/local/bin/docker-entrypoint.sh "$@"