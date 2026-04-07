#!/bin/bash
# create-dmg.sh — Package BotCrew.app into a DMG
# Usage: ./scripts/create-dmg.sh <path-to-app> <version>
# Example: ./scripts/create-dmg.sh build/BotCrew.app 0.2.0

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <path-to-app> <version>"
    exit 1
fi

APP_PATH="$1"
VERSION="$2"
DMG_NAME="BotCrew-${VERSION}.dmg"
STAGING_DIR=$(mktemp -d)

echo "==> Staging DMG contents..."
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG: $DMG_NAME"
hdiutil create \
    -volname "BotCrew ${VERSION}" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

echo "==> Cleaning up staging directory..."
rm -rf "$STAGING_DIR"

echo "==> Done: $DMG_NAME"
