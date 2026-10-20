#!/bin/sh
# Checks how /quant/quant-include.php derives WP_HOME from the request host.
# Run inside the built image: docker run --rm --entrypoint sh <image> /tests/quant-include-host.sh
set -u

INCLUDE="${QUANT_INCLUDE:-/quant/quant-include.php}"
failures=0

# check <description> <expected WP_HOME or UNDEFINED> <php $_SERVER assignments>
check() {
    actual=$(php -r "$3 require '$INCLUDE'; echo defined('WP_HOME') ? WP_HOME : 'UNDEFINED';" 2>&1)
    if [ "$actual" = "$2" ]; then
        echo "PASS: $1"
    else
        echo "FAIL: $1 (expected '$2', got '$actual')"
        failures=$((failures + 1))
    fi
}

check "edge host header wins" "https://kccc.org.au" \
    "\$_SERVER['HTTP_HOST']='10.3.55.124'; \$_SERVER['HTTP_QUANT_ORIG_HOST']='kccc.org.au'; \$_SERVER['HTTP_X_FORWARDED_PROTO']='https';"
check "real hostname is used" "https://devel.example.com.au" \
    "\$_SERVER['HTTP_HOST']='devel.example.com.au'; \$_SERVER['HTTP_X_FORWARDED_PROTO']='https';"
check "ALB health check IP host is ignored" "UNDEFINED" \
    "\$_SERVER['HTTP_HOST']='10.3.55.124';"
check "IP host with port is ignored" "UNDEFINED" \
    "\$_SERVER['HTTP_HOST']='10.3.55.124:80';"
check "localhost is ignored" "UNDEFINED" \
    "\$_SERVER['HTTP_HOST']='localhost';"
check "localhost with port is ignored" "UNDEFINED" \
    "\$_SERVER['HTTP_HOST']='localhost:80';"
check "bracketed IPv6 host is ignored" "UNDEFINED" \
    "\$_SERVER['HTTP_HOST']='[::1]:80';"
check "CLI with no host leaves WP_HOME undefined" "UNDEFINED" ""

if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed"
    exit 1
fi
echo "All checks passed"
