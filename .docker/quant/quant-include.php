<?php
// Quant Cloud dynamic host include
// Executed from wp-config.php before wp-settings.php

// Custom error handler - WordPress overrides php.ini, so we need runtime control
$quant_debug_mode = !empty($_ENV['LOG_DEBUG']) || !empty($_ENV['QUANT_DEBUG']);
define('QUANT_DEBUG_MODE', $quant_debug_mode);

set_error_handler(function($severity, $message, $file, $line) use ($quant_debug_mode) {
    // Always log critical errors (fatal, parse, core, compile, user, recoverable)
    $critical_errors = E_ERROR | E_PARSE | E_CORE_ERROR | E_COMPILE_ERROR | E_USER_ERROR | E_RECOVERABLE_ERROR;
    
    if ($severity & $critical_errors) {
        error_log("PHP Error [$severity]: $message in $file on line $line");
        return false; // Let PHP handle fatal errors normally
    }
    
    // In debug mode, log warnings/notices with different prefix
    if ($quant_debug_mode) {
        error_log("PHP Debug [$severity]: $message in $file on line $line");
        return true;
    }
    
    // Suppress warnings/notices in production by returning true (handled)
    return true;
}, E_ALL);

// Prevent WordPress from overriding our error settings
if (!defined('WP_DEBUG')) define('WP_DEBUG', false);
if (!defined('WP_DEBUG_LOG')) define('WP_DEBUG_LOG', false);  
if (!defined('WP_DEBUG_DISPLAY')) define('WP_DEBUG_DISPLAY', false);

// Only log configuration in debug mode to avoid log noise
if ($quant_debug_mode) {
    error_log("[Quant] Custom error handler active - warnings/notices enabled (debug: ON)");
}

// Normalize HTTPS behind proxy/edge
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    $_SERVER['HTTPS'] = 'on';
}

// Prefer edge host when provided
if (!empty($_SERVER['HTTP_QUANT_ORIG_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_QUANT_ORIG_HOST'];
}

$__quant_host = $_SERVER['HTTP_HOST'] ?? null;
if ($__quant_host) {
    $__quant_scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    define('WP_HOME', $__quant_scheme . '://' . $__quant_host);
    define('WP_SITEURL', $__quant_scheme . '://' . $__quant_host);
}

unset($__quant_host, $__quant_scheme);

// Enable TLS/SSL for database connections (RDS with enforced TLS)
if (!defined('MYSQL_CLIENT_FLAGS')) {
    define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL);
}

// Store email configuration for WordPress (to be used by mu-plugin later)
if (!empty($_ENV['QUANT_SMTP_FROM'])) {
    define('QUANT_SMTP_FROM_EMAIL', $_ENV['QUANT_SMTP_FROM']);
    // Only log in debug mode to avoid request noise
    if ($quant_debug_mode) {
        error_log("[Quant] QUANT_SMTP_FROM stored: " . $_ENV['QUANT_SMTP_FROM']);
    }
}

if (!empty($_ENV['QUANT_SMTP_FROM_NAME'])) {
    define('QUANT_SMTP_FROM_NAME_VALUE', $_ENV['QUANT_SMTP_FROM_NAME']);
    // Only log in debug mode to avoid request noise
    if ($quant_debug_mode) {
        error_log("[Quant] QUANT_SMTP_FROM_NAME stored: " . $_ENV['QUANT_SMTP_FROM_NAME']);
    }
}
