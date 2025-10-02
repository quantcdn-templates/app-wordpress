# Custom Entrypoint Scripts

This directory is for **custom entrypoint scripts** that are specific to your WordPress application.

## Important Note

The base image (`ghcr.io/quantcdn-templates/app-apache-php`) already provides standard Quant integration features including:

- SMTP relay configuration (`00-smtp-relay.sh`)
- Lightweight SMTP setup (`00-ssmtp.sh`) 
- Environment variable mapping
- Quant platform integration

**You should only add custom entrypoint scripts here if you need application-specific setup that isn't provided by the base image.**

## Adding Custom Entrypoint Scripts

1. Create a new shell script file (e.g., `10-custom-setup.sh`)
2. Make sure it's executable: `chmod +x 10-custom-setup.sh`
3. Use numeric prefixes to control execution order:
   - `00-` - Runs first (reserved for base image)
   - `10-` - Early custom scripts
   - `50-` - Mid-stage custom scripts
   - `90-` - Late-stage custom scripts

## Example Custom Script

```bash
#!/bin/bash
# 10-wordpress-custom.sh

echo "Setting up custom WordPress configuration..."

# Example: Set up custom wp-content permissions
if [ -d "/var/www/html/wp-content" ]; then
    chown -R www-data:www-data /var/www/html/wp-content
    echo "✅ WordPress content permissions updated"
fi

# Example: Create custom directories
mkdir -p /var/www/html/custom-uploads
chown www-data:www-data /var/www/html/custom-uploads
echo "✅ Custom upload directory created"
```

## Script Requirements

- Must be executable (`chmod +x`)
- Should use `#!/bin/bash` shebang
- Should include error checking and logging
- Should be idempotent (safe to run multiple times)
- Should not conflict with base image functionality

## Execution Order

Scripts are executed in alphabetical order by the Quant platform. The base image provides scripts with `00-` prefixes, so use higher numbers for your custom scripts.