# DDEV Local Development Setup

This WordPress template includes DDEV configuration for easy local development.

## Quick Start

1. **Install DDEV**: Follow instructions at https://ddev.readthedocs.io/en/stable/users/install/
2. **Start DDEV**: `ddev start`
3. **Access your site**: DDEV will show you the URL (typically `https://wordpress-template.ddev.site`)
4. **Complete WordPress setup**: Follow the WordPress installation wizard

## What's Included

### Services
- **Web**: PHP 8.3 with Apache-FPM (matches production)
- **Database**: MySQL 8.0 (matches production)

### Configuration Matches Production
- **PHP settings**: Same memory limits as production Dockerfile  
- **Environment variables**: Uses both `DB_*` and `WORDPRESS_DB_*` variables
- **WordPress debugging**: Enabled for development
- **WP-CLI**: Available via `ddev wp [command]`

### Development Features
- **Xdebug**: Available via `ddev xdebug on`
- **WP-CLI**: Integrated with `ddev wp [command]`
- **Database**: Import/export via `ddev import-db` / `ddev export-db`
- **Auto-setup**: WordPress core and config created automatically

## Common Commands

```bash
# Start/stop
ddev start
ddev stop

# WP-CLI commands
ddev wp --info
ddev wp plugin list
ddev wp theme list
ddev wp user create admin admin@example.com --role=administrator

# Database operations
ddev import-db --file=backup.sql
ddev export-db > backup.sql

# Debugging
ddev xdebug on
ddev logs -f
```

## WordPress Development

### Installing Plugins/Themes
```bash
# Via WP-CLI
ddev wp plugin install akismet --activate
ddev wp theme install twentytwentyfive --activate

# Via WordPress admin
# Visit your DDEV URL and use the admin interface
```

### Environment Variables
The DDEV setup automatically provides:
- Database connection details
- WordPress debugging enabled
- Both legacy and modern environment variable formats

## Production Consistency

This DDEV setup mirrors the production Docker configuration:
- Same PHP version and settings
- Same environment variable handling
- Same WP-CLI availability
- Compatible database settings 
