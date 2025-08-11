#!/bin/bash

# Execute all scripts in /quant/entrypoints/ then switch to www-data user

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Running Quant entrypoints as root..." >&2

if [ -d /quant/entrypoints ]; then
  for i in /quant/entrypoints/*; do
    if [ -r $i ]; then
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] Executing entrypoint: $(basename $i)" >&2
      . $i
    fi
  done
  unset i
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Quant entrypoints complete" >&2
else
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] No /quant/entrypoints directory found" >&2
fi

# Switch to www-data user for the main application
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Switching to www-data user for application..." >&2
exec gosu www-data "$@"