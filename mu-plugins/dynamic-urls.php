<?php
// Dynamic URLs for multi-host deployments
// Ensures WP_HOME, WP_SITEURL, and uploads baseurl reflect the current request

// Normalize HTTPS behind proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    $_SERVER['HTTPS'] = 'on';
}

// Prefer Quant-Orig-Host for the effective host seen by WordPress and plugins
if (!empty($_SERVER['HTTP_QUANT_ORIG_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_QUANT_ORIG_HOST'];
}

// Resolve current host with Quant precedence
function dynurls_current_host(): ?string {
    if (!empty($_SERVER['HTTP_QUANT_ORIG_HOST'])) {
        return $_SERVER['HTTP_QUANT_ORIG_HOST'];
    }
    return $_SERVER['HTTP_HOST'] ?? null;
}

// Define WP_HOME and WP_SITEURL as early as possible (pre-init)
$__dyn_host = dynurls_current_host();
if ($__dyn_host) {
    $__dyn_scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    if (!defined('WP_HOME')) {
        define('WP_HOME', $__dyn_scheme . '://' . $__dyn_host);
    }
    if (!defined('WP_SITEURL')) {
        define('WP_SITEURL', $__dyn_scheme . '://' . $__dyn_host);
    }
}