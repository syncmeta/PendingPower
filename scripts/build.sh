#!/usr/bin/env bash
# Build PendingPower.app from the SPM executable.
# Usage: scripts/build.sh [--sign "Developer ID Application: Your Name (TEAMID)"]
#
# Builds to /tmp/PendingPower-build to avoid iCloud Drive's file-provider
# re-attaching com.apple.FinderInfo xattrs (which codesign rejects).
# A symlink at <project>/build points at the tmp dir for convenience.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SIGN_IDENTITY=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign) SIGN_IDENTITY="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

APP_NAME="PendingPower"
BUILD_DIR="${PENDINGPOWER_BUILD_DIR:-/tmp/PendingPower-build}"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
SWIFT_BUILD_PATH="$BUILD_DIR/swift-build"

mkdir -p "$BUILD_DIR"

# Convenience: <project>/build -> tmp build dir
if [[ ! -e "$ROOT/build" || -L "$ROOT/build" ]]; then
    rm -f "$ROOT/build"
    ln -s "$BUILD_DIR" "$ROOT/build"
elif [[ -d "$ROOT/build" && ! -L "$ROOT/build" ]]; then
    echo "==> moving stale build/ aside (was a real dir, replacing with symlink to $BUILD_DIR)"
    rm -rf "$ROOT/build"
    ln -s "$BUILD_DIR" "$ROOT/build"
fi

echo "==> swift build (release, arm64) — output in $SWIFT_BUILD_PATH"
swift build -c release --arch arm64 --build-path "$SWIFT_BUILD_PATH"

BIN_PATH="$(swift build -c release --arch arm64 --build-path "$SWIFT_BUILD_PATH" --show-bin-path)"

echo "==> assembling $APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
# Use ditto: it does not preserve source xattrs the way cp can.
ditto "$BIN_PATH/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
ditto "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    ditto "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Belt-and-braces: strip any extended attributes anyway.
xattr -cr "$APP_DIR"

if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "==> codesign with: $SIGN_IDENTITY"
    codesign --force --options runtime --timestamp \
        --entitlements "$ROOT/Resources/Entitlements.plist" \
        --sign "$SIGN_IDENTITY" \
        "$APP_DIR"
    codesign --verify --deep --strict --verbose=2 "$APP_DIR"
else
    echo "==> ad-hoc signing (no Developer ID provided)"
    codesign --force --sign - "$APP_DIR"
fi

echo "==> done: $APP_DIR"
