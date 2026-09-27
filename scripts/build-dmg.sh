#!/usr/bin/env bash
# Full release pipeline: build → sign → notarize → staple → DMG + Sparkle feed.
#
# Prerequisites (run once on this machine):
#   xcrun notarytool store-credentials AC_PROFILE \
#       --apple-id "you@example.com" \
#       --team-id "TEAMID" \
#       --password "app-specific-password"
#
# Usage:
#   scripts/build-dmg.sh \
#       --sign "Developer ID Application: Your Name (TEAMID)" \
#       --notary-profile AC_PROFILE \
#       --sparkle-account YOUR_SPARKLE_KEYCHAIN_ACCOUNT
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SIGN_IDENTITY=""
NOTARY_PROFILE=""
SPARKLE_ACCOUNT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign) SIGN_IDENTITY="$2"; shift 2 ;;
        --notary-profile) NOTARY_PROFILE="$2"; shift 2 ;;
        --sparkle-account) SPARKLE_ACCOUNT="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [[ -z "$SIGN_IDENTITY" || -z "$NOTARY_PROFILE" || -z "$SPARKLE_ACCOUNT" ]]; then
    echo "Usage: $0 --sign \"Developer ID Application: ...\" --notary-profile <profile> --sparkle-account <keychain-account>"
    exit 1
fi

APP_NAME="PendingPower"
# Match build.sh — keep all artifacts outside iCloud-synced paths so xattrs
# don't get re-attached between codesign and notarize.
BUILD_DIR="${PENDINGPOWER_BUILD_DIR:-/tmp/PendingPower-build}"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$ROOT/Resources/Info.plist")"
UPDATE_DIR="$BUILD_DIR/updates"
UPDATE_ZIP="$UPDATE_DIR/$APP_NAME-v$VERSION.zip"
APPCAST="$UPDATE_DIR/appcast.xml"
SPARKLE_BIN="$BUILD_DIR/swift-build/artifacts/sparkle/Sparkle/bin"

echo "==> step 1/5: build & sign .app"
"$ROOT/scripts/build.sh" --sign "$SIGN_IDENTITY"

echo "==> step 2/5: zip for notarization"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo "==> step 3/5: notarize (waits until Apple finishes)"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> step 4/5: staple ticket onto the .app"
xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"

echo "==> create signed Sparkle update ZIP and appcast"
mkdir -p "$UPDATE_DIR"
rm -f "$UPDATE_ZIP" "$APPCAST"
ditto -c -k --keepParent "$APP_DIR" "$UPDATE_ZIP"
"$SPARKLE_BIN/generate_appcast" \
    --account "$SPARKLE_ACCOUNT" \
    --download-url-prefix "https://github.com/syncmeta/PendingPower/releases/download/v$VERSION/" \
    "$UPDATE_DIR"
"$SPARKLE_BIN/sign_update" --account "$SPARKLE_ACCOUNT" --verify "$APPCAST"
xmllint --noout "$APPCAST"

echo "==> step 5/5: build DMG (drag-to-Applications layout)"
rm -f "$DMG_PATH"

if ! command -v create-dmg >/dev/null 2>&1; then
    echo "ERROR: create-dmg not found. Install with: brew install create-dmg" >&2
    exit 1
fi

create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 380 \
    --icon-size 110 \
    --icon "$APP_NAME.app" 160 180 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 440 180 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_DIR"

codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "==> done: $DMG_PATH, $UPDATE_ZIP, $APPCAST"
