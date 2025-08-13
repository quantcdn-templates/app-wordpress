<?php
/**
 * Plugin Name: Quant Environment Configuration
 * Description: Automatically configure Quant plugin settings from environment variables
 * Version: 1.0.0
 * 
 * This is a mu-plugin (must-use plugin) that automatically sets Quant plugin
 * configuration from environment variables. Place this file in wp-content/mu-plugins/
 * 
 * Environment Variables:
 * - QUANT_ENABLED: Enable/disable Quant integration (1 or 0)
 * - QUANT_DISABLE_TLS_VERIFY: Disable SSL verification (1 or 0)
 * - QUANT_HTTP_REQUEST_TIMEOUT: HTTP request timeout in seconds
 * - QUANT_WEBSERVER_URL: Local webserver URL for HTTP requests
 * - QUANT_WEBSERVER_HOST: Hostname your webserver expects
 * - QUANT_API_ENDPOINT: Quant API endpoint URL
 * - QUANT_CUSTOMER: Sets the API Customer (api_account)
 * - QUANT_PROJECT: Sets the API Project (api_project) 
 * - QUANT_TOKEN: Sets the API Token (api_token)
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Configure Quant settings from environment variables
 */
function quant_configure_from_env() {
    // Ensure the Quant plugin constants are available
    if (!defined('QUANT_SETTINGS_KEY')) {
        return;
    }
    
    // Get current Quant settings
    $settings = get_option(QUANT_SETTINGS_KEY, []);
    $updated = false;
    
    // Set Quant Enabled from QUANT_ENABLED environment variable
    if (isset($_ENV['QUANT_ENABLED']) || getenv('QUANT_ENABLED') !== false) {
        $enabled = isset($_ENV['QUANT_ENABLED']) ? $_ENV['QUANT_ENABLED'] : getenv('QUANT_ENABLED');
        $enabled = (int) filter_var($enabled, FILTER_VALIDATE_BOOLEAN);
        if (($settings['enabled'] ?? 0) !== $enabled) {
            $settings['enabled'] = $enabled;
            $updated = true;
            error_log('Quant: Set Enabled to ' . ($enabled ? 'true' : 'false') . ' from QUANT_ENABLED environment variable');
        }
    }
    
    // Set Disable TLS Verify from QUANT_DISABLE_TLS_VERIFY environment variable  
    if (isset($_ENV['QUANT_DISABLE_TLS_VERIFY']) || getenv('QUANT_DISABLE_TLS_VERIFY') !== false) {
        $disable_tls = isset($_ENV['QUANT_DISABLE_TLS_VERIFY']) ? $_ENV['QUANT_DISABLE_TLS_VERIFY'] : getenv('QUANT_DISABLE_TLS_VERIFY');
        $disable_tls = (int) filter_var($disable_tls, FILTER_VALIDATE_BOOLEAN);
        if (($settings['disable_tls_verify'] ?? 0) !== $disable_tls) {
            $settings['disable_tls_verify'] = $disable_tls;
            $updated = true;
            error_log('Quant: Set Disable TLS Verify to ' . ($disable_tls ? 'true' : 'false') . ' from QUANT_DISABLE_TLS_VERIFY environment variable');
        }
    }
    
    // Set HTTP Request Timeout from QUANT_HTTP_REQUEST_TIMEOUT environment variable
    if (!empty($_ENV['QUANT_HTTP_REQUEST_TIMEOUT']) || !empty(getenv('QUANT_HTTP_REQUEST_TIMEOUT'))) {
        $timeout = !empty($_ENV['QUANT_HTTP_REQUEST_TIMEOUT']) ? $_ENV['QUANT_HTTP_REQUEST_TIMEOUT'] : getenv('QUANT_HTTP_REQUEST_TIMEOUT');
        $timeout = (int) $timeout;
        if ($timeout > 0 && ($settings['http_request_timeout'] ?? 15) !== $timeout) {
            $settings['http_request_timeout'] = $timeout;
            $updated = true;
            error_log('Quant: Set HTTP Request Timeout to ' . $timeout . ' from QUANT_HTTP_REQUEST_TIMEOUT environment variable');
        }
    }
    
    // Set Webserver URL from QUANT_WEBSERVER_URL environment variable
    if (!empty($_ENV['QUANT_WEBSERVER_URL']) || !empty(getenv('QUANT_WEBSERVER_URL'))) {
        $webserver_url = !empty($_ENV['QUANT_WEBSERVER_URL']) ? $_ENV['QUANT_WEBSERVER_URL'] : getenv('QUANT_WEBSERVER_URL');
        if (($settings['webserver_url'] ?? '') !== $webserver_url) {
            $settings['webserver_url'] = $webserver_url;
            $updated = true;
            error_log('Quant: Set Webserver URL from QUANT_WEBSERVER_URL environment variable');
        }
    }
    
    // Set Webserver Host from QUANT_WEBSERVER_HOST environment variable
    if (!empty($_ENV['QUANT_WEBSERVER_HOST']) || !empty(getenv('QUANT_WEBSERVER_HOST'))) {
        $webserver_host = !empty($_ENV['QUANT_WEBSERVER_HOST']) ? $_ENV['QUANT_WEBSERVER_HOST'] : getenv('QUANT_WEBSERVER_HOST');
        if (($settings['webserver_host'] ?? '') !== $webserver_host) {
            $settings['webserver_host'] = $webserver_host;
            $updated = true;
            error_log('Quant: Set Webserver Host from QUANT_WEBSERVER_HOST environment variable');
        }
    }
    
    // Set API Endpoint from QUANT_API_ENDPOINT environment variable
    if (!empty($_ENV['QUANT_API_ENDPOINT']) || !empty(getenv('QUANT_API_ENDPOINT'))) {
        $api_endpoint = !empty($_ENV['QUANT_API_ENDPOINT']) ? $_ENV['QUANT_API_ENDPOINT'] : getenv('QUANT_API_ENDPOINT');
        if (($settings['api_endpoint'] ?? 'https://api.quantcdn.io') !== $api_endpoint) {
            $settings['api_endpoint'] = $api_endpoint;
            $updated = true;
            error_log('Quant: Set API Endpoint from QUANT_API_ENDPOINT environment variable');
        }
    }
    
    // Set API Customer from QUANT_CUSTOMER environment variable
    if (!empty($_ENV['QUANT_CUSTOMER']) || !empty(getenv('QUANT_CUSTOMER'))) {
        $customer = !empty($_ENV['QUANT_CUSTOMER']) ? $_ENV['QUANT_CUSTOMER'] : getenv('QUANT_CUSTOMER');
        if ($settings['api_account'] !== $customer) {
            $settings['api_account'] = $customer;
            $updated = true;
            error_log('Quant: Set API Customer from QUANT_CUSTOMER environment variable');
        }
    }
    
    // Set API Project from QUANT_PROJECT environment variable
    if (!empty($_ENV['QUANT_PROJECT']) || !empty(getenv('QUANT_PROJECT'))) {
        $project = !empty($_ENV['QUANT_PROJECT']) ? $_ENV['QUANT_PROJECT'] : getenv('QUANT_PROJECT');
        if ($settings['api_project'] !== $project) {
            $settings['api_project'] = $project;
            $updated = true;
            error_log('Quant: Set API Project from QUANT_PROJECT environment variable');
        }
    }
    
    // Set API Token from QUANT_TOKEN environment variable
    if (!empty($_ENV['QUANT_TOKEN']) || !empty(getenv('QUANT_TOKEN'))) {
        $token = !empty($_ENV['QUANT_TOKEN']) ? $_ENV['QUANT_TOKEN'] : getenv('QUANT_TOKEN');
        if ($settings['api_token'] !== $token) {
            $settings['api_token'] = $token;
            $updated = true;
            error_log('Quant: Set API Token from QUANT_TOKEN environment variable');
        }
    }
    
    // Update the options if any changes were made
    if ($updated) {
        update_option(QUANT_SETTINGS_KEY, $settings);
        error_log('Quant: Configuration updated from environment variables');
    }
}

/**
 * Hook into WordPress initialization to configure Quant from environment variables
 * 
 * We use 'plugins_loaded' with a high priority to ensure the Quant plugin
 * has loaded and defined its constants, but before the settings are used
 */
add_action('plugins_loaded', 'quant_configure_from_env', 20);

/**
 * Optional: Also run on admin_init to ensure settings are updated when
 * the admin area is accessed (useful for debugging/verification)
 */
add_action('admin_init', 'quant_configure_from_env', 5);

/**
 * Example Environment Variables Configuration:
 * 
 * # General Settings
 * QUANT_ENABLED=1
 * QUANT_DISABLE_TLS_VERIFY=0
 * QUANT_HTTP_REQUEST_TIMEOUT=30
 * QUANT_WEBSERVER_URL=http://localhost
 * QUANT_WEBSERVER_HOST=www.example.com
 * 
 * # API Settings  
 * QUANT_API_ENDPOINT=https://api.quantcdn.io
 * QUANT_CUSTOMER=your-customer-id
 * QUANT_PROJECT=your-project-name
 * QUANT_TOKEN=your-secret-api-token
 * 
 * Note: Boolean values (QUANT_ENABLED, QUANT_DISABLE_TLS_VERIFY) accept:
 * - 1, true, yes, on for TRUE
 * - 0, false, no, off for FALSE
 */