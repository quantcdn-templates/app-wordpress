#!/bin/bash
set -euo pipefail

# This wrapper runs Quant post-WordPress setup first, then starts Apache

# Run Quant post-WordPress setup, then start Apache using the original apache2-foreground
/usr/local/bin/quant-post-wordpress-setup.sh apache2-foreground