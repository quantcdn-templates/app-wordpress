#!/bin/sh
# wordpress-core-update.sh <version> <core dir>
#
# Replaces the WordPress core in <core dir> with release <version> from wordpress.org
# when the installed core is a different version. Keeps wp-config-docker.php and
# .htaccess, which the official image adds. Verifies the download against the
# .sha1 that wordpress.org publishes. An empty <version> changes nothing.
set -eu

want="${1:-}"
dir="$2"
base="${WORDPRESS_DOWNLOAD_BASE:-https://wordpress.org}"

version_of() { sed -n "s/^\$wp_version = '\(.*\)';/\1/p" "$1/wp-includes/version.php"; }
sha1() { if command -v sha1sum >/dev/null 2>&1; then sha1sum "$1" | cut -d' ' -f1; else shasum -a 1 "$1" | cut -d' ' -f1; fi; }

[ -n "$want" ] || { echo "WordPress core: keeping $(version_of "$dir") from the official image"; exit 0; }

have=$(version_of "$dir")
[ "$have" != "$want" ] || { echo "WordPress core: $have is current"; exit 0; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/wordpress.tar.gz" "$base/wordpress-$want.tar.gz"
expected=$(curl -fsSL "$base/wordpress-$want.tar.gz.sha1" | cut -c1-40)
actual=$(sha1 "$tmp/wordpress.tar.gz")
[ "$expected" = "$actual" ] || { echo "WordPress core: checksum mismatch for $want" >&2; exit 1; }

tar -xzf "$tmp/wordpress.tar.gz" -C "$tmp"
[ "$(version_of "$tmp/wordpress")" = "$want" ] || { echo "WordPress core: archive is not $want" >&2; exit 1; }
for keep in wp-config-docker.php .htaccess; do
    [ ! -e "$dir/$keep" ] || cp -p "$dir/$keep" "$tmp/wordpress/$keep"
done
# The official image makes wp-content world-writable (sticky); keep that.
chmod -R 1777 "$tmp/wordpress/wp-content"

rm -rf "$dir"
mv "$tmp/wordpress" "$dir"
echo "WordPress core: $have -> $want"
