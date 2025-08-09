<?php
// Quant Cloud dynamic host include
// Executed from wp-config.php before wp-settings.php

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

