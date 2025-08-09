<?php
// Dynamic URLs for multi-host deployments
// Ensures WP_HOME, WP_SITEURL, and uploads baseurl reflect the current request

// Normalize HTTPS behind proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    $_SERVER['HTTPS'] = 'on';
}

// Resolve current host with Quant precedence
function dynurls_current_host(): ?string {
    if (!empty($_SERVER['HTTP_QUANT_ORIG_HOST'])) {
        return $_SERVER['HTTP_QUANT_ORIG_HOST'];
    }
    return $_SERVER['HTTP_HOST'] ?? null;
}

// Set WP_HOME and WP_SITEURL dynamically if not already defined
add_action('init', function () {
    $host = dynurls_current_host();
    if (!$host) {
        return;
    }
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    if (!defined('WP_HOME')) {
        define('WP_HOME', $scheme . '://' . $host);
    }
    if (!defined('WP_SITEURL')) {
        define('WP_SITEURL', $scheme . '://' . $host);
    }
});

// Force uploads baseurl to current host
add_filter('upload_dir', function ($data) {
    $host = dynurls_current_host();
    if (!$host) {
        return $data;
    }
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $data['baseurl'] = $scheme . '://' . $host . '/wp-content/uploads';
    return $data;
}, 99);

