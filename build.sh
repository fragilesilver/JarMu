#!/bin/sh
# build.sh - Assemble the JarMu .muxapp release archive.
#
# Usage:
#   ./build.sh [version]
#
# Default version is read from VERSION file or defaults to "dev".
# Output: dist/JarMu-<version>.muxapp

set -e

VERSION="${1:-$(cat VERSION 2>/dev/null || echo dev)}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/source"
DIST="$ROOT/dist"
STAGE="$DIST/build/mnt/mmc/MUOS/application/JarMu"

echo "==> Building JarMu $VERSION"

rm -rf "$DIST"
mkdir -p "$STAGE"

cp -r "$SRC/love"           "$STAGE/"
cp -r "$SRC/game"           "$STAGE/"
cp -r "$SRC/glyph"          "$STAGE/"
cp    "$SRC/mux_launch.ini" "$STAGE/"
cp    "$SRC/mux_launch.sh"  "$STAGE/"

chmod +x "$STAGE/mux_launch.sh"
chmod +x "$STAGE/love/love"

cd "$DIST/build"
zip -qr "../JarMu-$VERSION.muxapp" . -x "*.DS_Store"

echo "==> Wrote dist/JarMu-$VERSION.muxapp"
ls -lh "$DIST/JarMu-$VERSION.muxapp"
