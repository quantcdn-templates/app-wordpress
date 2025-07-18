# WordPress Template for Quant Cloud

A production-ready WordPress template designed for deployment on Quant Cloud. This template uses the standard WordPress Docker image with intelligent environment variable mapping to support Quant Cloud's database configuration.

## Features

- **WordPress Latest**: Based on the official WordPress Docker image
- **Standard Configuration**: Uses WordPress's built-in `wp-config-docker.php` with environment variable mapping
- **Quant Cloud Integration**: Maps Quant Cloud's `DB_*` variables to WordPress standards
- **Production Ready**: Includes health checks, proper file permissions, and security considerations
- **CI/CD Integration**: GitHub Actions workflow for automated building and deployment
- **Multi-Registry Support**: Pushes to both GitHub Container Registry and Quant Cloud Registry
- **Database Ready**: Works with Quant Cloud's managed database service

## Quick Start

### Local Development

1. Clone this repository
2. Copy the environment file:
   ```bash
   cp .env.example .env
   ```
3. Edit the `.env` file with your configuration
4. Start the services:
   ```bash
   docker-compose up -d
   ```
5. Access WordPress at http://localhost

### Environment Variables

The template supports Quant Cloud's standard database environment variables:

#### Database Configuration (Quant Cloud Standard)
| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | `db` |
| `DB_PORT` | Database port | `3306` |
| `DB_DATABASE` | Database name | `wordpress` |
| `DB_USERNAME` | Database username | `wordpress` |
| `DB_PASSWORD` | Database password | `wordpress` |

#### WordPress Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `WORDPRESS_TABLE_PREFIX` | Table prefix | `wp_` |
| `WORDPRESS_DEBUG` | Enable debug mode | `false` |
| `WORDPRESS_DEBUG_LOG` | Enable debug logging | `false` |
| `WORDPRESS_DEBUG_DISPLAY` | Display debug info | `false` |
| `WP_CONFIG_EXTRA` | Additional PHP configuration | `` |

### WordPress Salt Keys

For security, you should set the following environment variables with unique values:

- `WORDPRESS_AUTH_KEY`
- `WORDPRESS_SECURE_AUTH_KEY`
- `WORDPRESS_LOGGED_IN_KEY`
- `WORDPRESS_NONCE_KEY`
- `WORDPRESS_AUTH_SALT`
- `WORDPRESS_SECURE_AUTH_SALT`
- `WORDPRESS_LOGGED_IN_SALT`
- `WORDPRESS_NONCE_SALT`

If not provided, WordPress will generate them automatically.

## How It Works

This template uses a smart approach to configuration:

1. **Standard WordPress Base**: Uses the official WordPress Docker image with its built-in `wp-config-docker.php`
2. **Environment Variable Mapping**: Maps Quant Cloud's `DB_*` variables to WordPress's expected `WORDPRESS_DB_*` variables
3. **Zero Configuration Override**: No custom wp-config.php files - just environment variable translation

### Environment Variable Mapping

The template automatically maps:
- `DB_HOST` + `DB_PORT` → `WORDPRESS_DB_HOST`
- `DB_DATABASE` → `WORDPRESS_DB_NAME`
- `DB_USERNAME` → `WORDPRESS_DB_USER`
- `DB_PASSWORD` → `WORDPRESS_DB_PASSWORD`
- `WP_CONFIG_EXTRA` → `WORDPRESS_CONFIG_EXTRA`

## Custom Configuration

### Method 1: Environment Variables (Recommended)

Set environment variables in your deployment:

```bash
export WP_CONFIG_EXTRA="define('WP_MEMORY_LIMIT', '256M'); define('WP_MAX_MEMORY_LIMIT', '512M');"
```

### Method 2: Extend the Image

Create a custom Dockerfile:

```dockerfile
FROM quantcdn-templates/app-wordpress:latest
ENV WP_CONFIG_EXTRA="define('WP_MEMORY_LIMIT', '512M');"
```

## CI/CD Pipeline

The template includes a GitHub Actions workflow that:

1. **Builds** multi-platform Docker images (AMD64 and ARM64)
2. **Pushes** to Quant Cloud's ECR registry
3. **Redeploys** the environment automatically
4. **Supports** staging (develop branch) and production (master branch) deployments
5. **Tags** releases with version suffixes

### Required Secrets

Configure these secrets in your GitHub repository:

#### Quant Cloud Secrets
- `QUANT_API_KEY` - Your Quant Cloud API key
- `QUANT_ORGANIZATION` - Your Quant Cloud organization name  
- `QUANT_APPLICATION` - Your application name in Quant Cloud

Database credentials are managed automatically by Quant Cloud and injected as environment variables at runtime.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   WordPress     │    │  Quant Cloud    │
│   Container     │◄──►│   Database      │
│                 │    │                 │
│ - Standard      │    │ - Managed       │
│   wp-config     │    │ - Scalable      │
│ - Env Mapping   │    │ - Secure        │
│ - Health Check  │    │                 │
└─────────────────┘    └─────────────────┘
```

## Health Checks

The template includes comprehensive health checks:

### WordPress Health Check
- **Test**: HTTP request to the WordPress homepage
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Start Period**: 60 seconds (allows WordPress to initialize)
- **Retries**: 3

### Database Health Check (Local Development Only)
- **Test**: MySQL ping command
- **Interval**: 10 seconds
- **Timeout**: 5 seconds
- **Retries**: 3

## File Structure

```
app-wordpress/
├── Dockerfile                     # WordPress image with env mapping
├── docker-compose.yml             # Local development setup
├── docker-entrypoint-custom.sh    # Custom entrypoint with env mapping
├── .env.example                   # Environment variables example
├── .github/
│   └── workflows/
│       ├── build-deploy.yaml      # Quant Cloud ECR deployment
│       └── ci.yml                 # GitHub Container Registry (public)
├── quant/
│   └── meta.json                  # Template metadata
└── README.md                      # This file
```

## Local Development vs Production

### Local Development
- Uses MySQL container (marked with `quant.type: none`)
- Full docker-compose stack
- File syncing for wp-content

### Quant Cloud Production
- Uses managed database service
- Single WordPress container
- Persistent storage for wp-content
- Automatic scaling and load balancing

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD` values
   - Verify database service is running (Quant Cloud manages this)
   - Check network connectivity

2. **Environment Variables Not Working**
   - Verify variable names match Quant Cloud standards (`DB_*`)
   - Check container logs for environment mapping output
   - Ensure variables are set in deployment environment

3. **Health Check Failures**
   - Check WordPress is fully started (60s start period)
   - Verify Apache is running
   - Check resource limits

### Logs

View container logs:
```bash
docker-compose logs -f wordpress
```

### Debug Mode

Enable debug mode:
```bash
export WORDPRESS_DEBUG=true
export WORDPRESS_DEBUG_LOG=true
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both local development and Quant Cloud deployment
5. Submit a pull request

## License

This template is released under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/quantcdn-templates/app-wordpress/issues)
- Documentation: [Quant Cloud Documentation](https://docs.quantcdn.io/)
- Community: [Quant Discord](https://discord.gg/quant) 