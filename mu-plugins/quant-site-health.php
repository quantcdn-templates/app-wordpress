<?php
/**
 * Plugin Name: Quant Site Health Customizations
 * Description: Customize Site Health checks for Quant Cloud environment
 * Version: 1.0.0
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Customize Site Health tests for Quant Cloud environment
 */
add_filter('site_status_tests', function($tests) {
    // Remove the async page_cache test and add our own as a direct test
    // (async tests use AJAX callbacks which are more complex to override)
    if (isset($tests['async']['page_cache'])) {
        unset($tests['async']['page_cache']);
    }

    // Add our page cache test as a direct test so it shows in results
    $tests['direct']['quant_page_cache'] = [
        'label' => __('Page Cache'),
        'test'  => 'quant_test_page_cache',
    ];

    // Replace plugin_version direct test (handles inactive plugins warning)
    if (isset($tests['direct']['plugin_version'])) {
        $tests['direct']['plugin_version']['test'] = 'quant_test_plugin_version';
    }

    // Replace theme_version direct test (handles inactive themes warning)
    if (isset($tests['direct']['theme_version'])) {
        $tests['direct']['theme_version']['test'] = 'quant_test_theme_version';
    }

    return $tests;
});

/**
 * Custom page cache test - explains Quant CDN handles caching
 */
function quant_test_page_cache() {
    return [
        'label'       => __('Page caching is handled by QuantCDN'),
        'status'      => 'good',
        'badge'       => [
            'label' => __('Performance'),
            'color' => 'blue',
        ],
        'description' => sprintf(
            '<p>%s</p>',
            __('This site is hosted on Quant Cloud, which provides edge caching through its global CDN. Server-side page caching plugins are not needed.')
        ),
        'actions'     => '',
        'test'        => 'page_cache',
    ];
}

/**
 * Custom plugin version test - runs default check but suppresses inactive plugin warning
 * only if the inactive plugins are the default WordPress bundled plugins (Hello Dolly, Akismet)
 */
function quant_test_plugin_version() {
    // Run the original test
    $site_health = WP_Site_Health::get_instance();
    $result = $site_health->get_test_plugin_version();

    // If the issue is about inactive plugins, check if they're only default WP plugins
    if ($result['status'] === 'recommended' &&
        strpos($result['label'], 'inactive') !== false) {

        // Get list of inactive plugins
        $all_plugins = get_plugins();
        $active_plugins = get_option('active_plugins', []);
        $inactive_plugins = array_diff(array_keys($all_plugins), $active_plugins);

        // Default WordPress bundled plugins (by directory/file path)
        $default_wp_plugins = [
            'hello.php',           // Hello Dolly (single file in plugins root)
            'akismet/akismet.php', // Akismet
        ];

        // Check if all inactive plugins are default WP plugins
        $only_default_inactive = true;
        foreach ($inactive_plugins as $plugin) {
            if (!in_array($plugin, $default_wp_plugins, true)) {
                $only_default_inactive = false;
                break;
            }
        }

        // Only suppress warning if all inactive plugins are default WP plugins
        if ($only_default_inactive) {
            $result['status'] = 'good';
            $result['label'] = __('Plugins are properly configured');
            $result['description'] = sprintf(
                '<p>%s</p>',
                __('Your plugins are up to date. The bundled WordPress plugins (Hello Dolly, Akismet) are available if needed but can remain inactive.')
            );
        }
    }

    return $result;
}

/**
 * Custom theme version test - runs default check but suppresses inactive theme warning
 * only if the inactive themes are the default WordPress bundled themes (twentytwenty*)
 */
function quant_test_theme_version() {
    // Run the original test
    $site_health = WP_Site_Health::get_instance();
    $result = $site_health->get_test_theme_version();

    // If the issue is about inactive themes, check if they're only default WP themes
    if ($result['status'] === 'recommended' &&
        strpos($result['label'], 'inactive') !== false) {

        // Get list of all themes and the active theme
        $all_themes = wp_get_themes();
        $active_theme = wp_get_theme();
        $active_stylesheet = $active_theme->get_stylesheet();

        // Check if all inactive themes are default WordPress themes (twentytwenty*)
        $only_default_inactive = true;
        foreach ($all_themes as $stylesheet => $theme) {
            // Skip the active theme
            if ($stylesheet === $active_stylesheet) {
                continue;
            }

            // Check if this inactive theme is a default WordPress theme
            // Default themes follow the pattern: twentytwenty, twentytwentyone, twentytwentytwo, etc.
            if (!preg_match('/^twentytwenty/', $stylesheet)) {
                $only_default_inactive = false;
                break;
            }
        }

        // Only suppress warning if all inactive themes are default WP themes
        if ($only_default_inactive) {
            $result['status'] = 'good';
            $result['label'] = __('Themes are properly configured');
            $result['description'] = sprintf(
                '<p>%s</p>',
                __('Your active theme is up to date. The bundled WordPress themes serve as fallbacks and can remain inactive.')
            );
        }
    }

    return $result;
}
