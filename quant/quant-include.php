<?php
// Quant Cloud dynamic host include
// Executed from wp-config.php before wp-settings.php

// Prevent WordPress and plugins from overriding our error reporting (configured in 99-quant-logging.ini)
if (!defined('WP_DEBUG')) define('WP_DEBUG', false);
if (!defined('WP_DEBUG_LOG')) define('WP_DEBUG_LOG', false);  
if (!defined('WP_DEBUG_DISPLAY')) define('WP_DEBUG_DISPLAY', false);

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

// Store email configuration for WordPress (to be used by mu-plugin later)
if (!empty($_ENV['QUANT_SMTP_FROM'])) {
    define('QUANT_SMTP_FROM_EMAIL', $_ENV['QUANT_SMTP_FROM']);
}

if (!empty($_ENV['QUANT_SMTP_FROM_NAME'])) {
    define('QUANT_SMTP_FROM_NAME_VALUE', $_ENV['QUANT_SMTP_FROM_NAME']);
}
