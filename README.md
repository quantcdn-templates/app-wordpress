# WordPress Template for Quant Cloud

A production-ready WordPress template designed for deployment on Quant Cloud. This template uses the standard WordPress Docker image with intelligent environment variable mapping to support Quant Cloud's database configuration.

## Features

- **WordPress Latest**: Based on the official WordPress Docker image
- **Standard Configuration**: Uses WordPress's built-in `wp-config-docker.php` with environment variable mapping
- **Quant Cloud Integration**: Maps Quant Cloud's `DB_*` variables to WordPress standards
- **Production Ready**: Includes health checks, proper file permissions, and security considerations
- **WP-CLI Included**: WordPress CLI tool pre-installed and configured
- **Privileged Port Binding**: Apache runs as root for port 80, workers run as www-data for security
- **CI/CD Integration**: GitHub Actions workflow for automated building and deployment
- **Multi-Registry Support**: Pushes to both GitHub Container Registry and Quant Cloud Registry
- **Database Ready**: Works with Quant Cloud's managed database service

## Deployment to Quant Cloud

This template provides two deployment options depending on your needs:

### 🚀 Quick Start (Recommended)

**Use our pre-built image** - Perfect for most users who want WordPress running quickly without customization.

1. **Import Template**: In [Quant Dashboard](https://dashboard.quantcdn.io), create a new application and import this `docker-compose.yml` directly
2. **Image Source**: The **"Public Registry"** image (`ghcr.io/quantcdn-templates/app-wordpress:latest`) will automatically be provided and used by default
3. **Deploy**: Save the application - your WordPress site will be live in minutes!

**What you get:**
- ✅ Latest WordPress version
- ✅ Automatic updates via our maintained image
- ✅ Zero configuration required
- ✅ Production-ready setup
- ✅ Works with Quant Cloud's managed database

### ⚙️ Advanced (Custom Build)

**Fork and customize** - For users who need custom plugins, themes, or configuration.

#### Step 1: Get the Template
- Click **"Use this template"** on GitHub, or fork this repository
- Clone your new repository locally

#### Step 2: Setup CI/CD Pipeline  
Add these secrets to your GitHub repository settings:
- `QUANT_API_KEY` - Your Quant Cloud API key
- `QUANT_ORGANIZATION` - Your organization slug (e.g., "my-company")  
- `QUANT_APPLICATION` - Your application name (e.g., "my-wordpress-site")

#### Step 3: Remove Public Registry CI
Since you'll be using your own registry, delete the public build file:
```bash
rm .github/workflows/ci.yml
```

#### Step 4: Create Application
1. In Quant Cloud, create a new application 
2. Import your `docker-compose.yml`
3. Select **"Internal Registry"** when prompted
4. This will use your custom built image from the Quant Cloud private registry

#### Step 5: Deploy
- Push to `master` branch → Production deployment
- Push to `develop` branch → Staging deployment  
- Create tags → Tagged releases

**What you get:**
- ✅ Full customization control
- ✅ Your own Docker registry
- ✅ Automated builds on git push
- ✅ Staging and production environments
- ✅ Version tagging support

---

## Local Development

For both deployment options, you can develop locally:

1. **Clone** your repo (or this template)
2. **Copy overrides**:
   ```bash
   cp docker-compose.override.yml.example docker-compose.override.yml
   ```
3. **Start services**:
   ```bash
   docker-compose up -d
   ```
4. **Access WordPress** at http://localhost

**Local vs Quant Cloud:**

| Feature | Local Development | Quant Cloud |
|---------|------------------|-------------|
| **Database** | MySQL container | Managed RDS |
| **Environment** | `docker-compose.override.yml` | Platform variables |
| **Storage** | Local volumes | EFS persistent storage |
| **Scaling** | Single container | Auto-scaling |
| **Debug** | Enabled by default | Production optimized |
| **Access** | localhost | Custom domains + CDN |

## Environment Variables

### Database Configuration (Automatic)
These are automatically provided by Quant Cloud:
- `DB_HOST` - Database host
- `DB_DATABASE` - Database name  
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password

### Optional WordPress Configuration
- `WORDPRESS_TABLE_PREFIX` - Table prefix (default: `wp_`)
- `WORDPRESS_DEBUG` - Enable debug mode (default: `false`)
- `WP_CONFIG_EXTRA` - Additional PHP configuration

**Example:**
```bash
export WP_CONFIG_EXTRA="define('WP_MEMORY_LIMIT', '256M'); define('UPLOAD_MAX_FILESIZE', '64M');"
```

## WP-CLI Support

This template includes WP-CLI (WordPress Command Line Interface) pre-installed and configured.

### Local Development
```bash
docker-compose exec wordpress wp --info
docker-compose exec wordpress wp core version
docker-compose exec wordpress wp plugin list
```

### Quant Cloud (via SSH/exec)
```bash
wp --info
wp core version  
wp plugin install akismet --activate
wp theme install twentytwentyfour --activate
```

WP-CLI automatically inherits the environment variables and database configuration, so it works seamlessly with both local and production environments.

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