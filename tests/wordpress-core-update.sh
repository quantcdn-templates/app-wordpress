#!/bin/sh
# Checks .docker/quant/scripts/wordpress-core-update.sh against fake WordPress releases.
# Runs on any host with sh, tar, curl and sha1sum (or shasum): sh tests/wordpress-core-update.sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
script="$here/../.docker/quant/scripts/wordpress-core-update.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

sha1() { if command -v sha1sum >/dev/null 2>&1; then sha1sum "$1" | cut -d' ' -f1; else shasum -a 1 "$1" | cut -d' ' -f1; fi; }

# release <version> <dir>: a fake wordpress-<version>.tar.gz and .sha1 in <dir>
release() {
    mkdir -p "$work/build/wordpress/wp-includes" "$work/build/wordpress/wp-content/themes" "$2"
    printf "<?php\n\$wp_version = '%s';\n" "$1" >"$work/build/wordpress/wp-includes/version.php"
    tar -czf "$2/wordpress-$1.tar.gz" -C "$work/build" wordpress
    sha1 "$2/wordpress-$1.tar.gz" >"$2/wordpress-$1.tar.gz.sha1"
    rm -rf "$work/build"
}

# install <version> <dir>: a fake core as the official image has it
install() {
    mkdir -p "$2/wp-includes" "$2/wp-admin"
    printf "<?php\n\$wp_version = '%s';\n" "$1" >"$2/wp-includes/version.php"
    echo old >"$2/wp-admin/removed-in-new.php"
    echo docker >"$2/wp-config-docker.php"
    echo rules >"$2/.htaccess"
}

version_of() { sed -n "s/^\$wp_version = '\(.*\)';/\1/p" "$1/wp-includes/version.php"; }

check() {
    if [ "$2" = "$3" ]; then echo "PASS: $1"; else echo "FAIL: $1 (expected '$2', got '$3')"; failures=$((failures + 1)); fi
}

release 7.1.4 "$work/dl"
export WORDPRESS_DOWNLOAD_BASE="file://$work/dl"

install 6.1.1 "$work/a"
sh "$script" 7.1.4 "$work/a" >/dev/null 2>&1
check "an old core is replaced" "7.1.4" "$(version_of "$work/a")"
check "files the new release does not ship are gone" "absent" "$([ -e "$work/a/wp-admin/removed-in-new.php" ] && echo present || echo absent)"
check "wp-config-docker.php is kept" "docker" "$(cat "$work/a/wp-config-docker.php" 2>/dev/null)"
check ".htaccess is kept" "rules" "$(cat "$work/a/.htaccess" 2>/dev/null)"

install 7.1.4 "$work/b"
sh "$script" 7.1.4 "$work/b" >/dev/null 2>&1
check "a current core is left alone" "present" "$([ -e "$work/b/wp-admin/removed-in-new.php" ] && echo present || echo absent)"

install 6.1.1 "$work/c"
sh "$script" "" "$work/c" >/dev/null 2>&1
check "an empty version keeps the official core" "6.1.1" "$(version_of "$work/c")"

install 6.1.1 "$work/d"
echo 0000000000000000000000000000000000000000 >"$work/dl/wordpress-7.1.4.tar.gz.sha1"
if sh "$script" 7.1.4 "$work/d" >/dev/null 2>&1; then failed=0; else failed=1; fi
check "a checksum mismatch fails the build" "1" "$failed"
check "a checksum mismatch leaves the core as it was" "6.1.1" "$(version_of "$work/d")"

install 6.1.1 "$work/e"
if sh "$script" 9.9.9 "$work/e" >/dev/null 2>&1; then failed=0; else failed=1; fi
check "a missing release fails the build" "1" "$failed"

[ "$failures" -eq 0 ] && echo "All checks passed" || { echo "$failures check(s) failed"; exit 1; }
