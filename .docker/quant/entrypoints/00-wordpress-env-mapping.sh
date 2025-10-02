#!/bin/bash

# Map Quant Cloud DB environment variables to WordPress format
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mapping Quant Cloud environment variables..." >&2

if [ -n "${DB_HOST:-}" ]; then
    if [ -n "${DB_PORT:-}" ] && [ "${DB_PORT}" != "3306" ]; then
        export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT}"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mapped DB_HOST:DB_PORT (${DB_HOST}:${DB_PORT}) to WORDPRESS_DB_HOST" >&2
    else
        export WORDPRESS_DB_HOST="${DB_HOST}"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mapped DB_HOST (${DB_HOST}) to WORDPRESS_DB_HOST" >&2
    fi
fi

if [ -n "${DB_DATABASE:-}" ]; then
    export WORDPRESS_DB_NAME="${DB_DATABASE}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mapped DB_DATABASE (${DB_DATABASE}) to WORDPRESS_DB_NAME" >&2
fi

if [ -n "${DB_USERNAME:-}" ]; then
    export WORDPRESS_DB_USER="${DB_USERNAME}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mapped DB_USERNAME to WORDPRESS_DB_USER" >&2
fi

if [ -n "${DB_PASSWORD:-}" ]; then
    export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mapped DB_PASSWORD to WORDPRESS_DB_PASSWORD" >&2
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Environment variable mapping complete" >&2