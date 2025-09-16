<?php
/**
 * Plugin Name: Quant Email Configuration
 * Description: Automatically configure WordPress email settings from environment variables
 * Version: 1.0.0
 *
 * The quant-email-config mu-plugin (must-use plugin) configures WordPress email
 * settings from environment variables. Place this file in wp-content/mu-plugins/
 *
 * Environment Variables:
 * - QUANT_SMTP_FROM_EMAIL: The STMP from email address
 * - QUANT_SMTP_FROM_NAME_VALUE: The SMTP from name
 * - QUANT_DEBUG_MODE: Debug mode (1 or 0)
 */

// Set default 'from' email address if QUANT_SMTP_FROM is configured
if (defined('QUANT_SMTP_FROM_EMAIL')) {
    add_filter('wp_mail_from', function($from_email) {
        // Only override if it's the default wordpress@domain format
        if (strpos($from_email, 'wordpress@') === 0) {
            return QUANT_SMTP_FROM_EMAIL;
        }
        return $from_email;
    });
    
    // Only log in debug mode to avoid request noise
    if (defined('QUANT_DEBUG_MODE') && QUANT_DEBUG_MODE) {
        error_log("[Quant] WordPress email 'from' address filter applied: " . QUANT_SMTP_FROM_EMAIL);
    }
}

// Set default 'from' name if QUANT_SMTP_FROM_NAME is configured
if (defined('QUANT_SMTP_FROM_NAME_VALUE')) {
    add_filter('wp_mail_from_name', function($from_name) {
        // Only override if it's the default 'WordPress' name
        if ($from_name === 'WordPress') {
            return QUANT_SMTP_FROM_NAME_VALUE;
        }
        return $from_name;
    });
    
    // Only log in debug mode to avoid request noise
    if (defined('QUANT_DEBUG_MODE') && QUANT_DEBUG_MODE) {
        error_log("[Quant] WordPress email 'from' name filter applied: " . QUANT_SMTP_FROM_NAME_VALUE);
    }
}
?>
