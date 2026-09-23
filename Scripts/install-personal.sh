#!/bin/bash
# Build the personal release and install it over /Applications/Tinycast.app, keeping a backup.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${DEVELOPER_DIR:-}" ]; then
    DEVELOPER_DIR=$(xcode-select -p)
    if [[ "$DEVELOPER_DIR" != *.app/Contents/Developer ]]; then
        XCODE=$(ls -d /Applications/Xcode*.app 2>/dev/null | sort -V | tail -n1)
        [ -n "$XCODE" ] || { echo "No Xcode found; set DEVELOPER_DIR" >&2; exit 1; }
        DEVELOPER_DIR="$XCODE/Contents/Developer"
    fi
fi
export DEVELOPER_DIR
echo "Using $DEVELOPER_DIR"

./Scripts/build-personal.sh
BUILT=build/PersonalDerivedData/Build/Products/Release/Tinycast.app
INSTALLED=/Applications/Tinycast.app
STAGE=/Applications/.Tinycast-staging.app
PREVIOUS=/Applications/.Tinycast-previous.app
plist() { /usr/libexec/PlistBuddy -c "Print $2" "$1/Contents/Info.plist" 2>/dev/null; }

VERSION=$(plist "$BUILT" CFBundleShortVersionString)
REVISION=$(plist "$BUILT" TinycastPatchRevision)
[ "$REVISION" = "$(git rev-parse HEAD)" ] || { echo "Built revision is not HEAD" >&2; exit 1; }
[ "$(plist "$BUILT" CFBundleIdentifier)" = com.tinycast.app ] || { echo "Wrong bundle ID" >&2; exit 1; }

# A downgrade can meet data written by the newer version, so it needs the data backed up by hand.
if [ -d "$INSTALLED" ]; then
    CURRENT=$(plist "$INSTALLED" CFBundleShortVersionString)
    if [ "$CURRENT" != "$VERSION" ] &&
        [ "$(printf '%s\n%s\n' "$CURRENT" "$VERSION" | sort -V | tail -n1)" = "$CURRENT" ]; then
        echo "Refusing to downgrade $CURRENT to $VERSION" >&2
        exit 1
    fi
fi

osascript -e 'tell application id "com.tinycast.app" to quit' >/dev/null 2>&1 || true
for _ in $(seq 1 40); do
    pgrep -f "$INSTALLED/Contents/MacOS/" >/dev/null || break
    sleep 0.25
done
if pgrep -f "$INSTALLED/Contents/MacOS/" >/dev/null; then
    echo "Tinycast is still running; quit it and retry" >&2
    exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=
if [ -d "$INSTALLED" ]; then
    BACKUP="build/installed-backup-${CURRENT:-unknown}-$STAMP/Tinycast.app"
    mkdir -p "$(dirname "$BACKUP")"
    ditto "$INSTALLED" "$BACKUP"
    codesign --verify --deep --strict "$BACKUP"
fi

rm -rf "$STAGE" "$PREVIOUS"
ditto "$BUILT" "$STAGE"
codesign --verify --deep --strict "$STAGE"
[ -d "$INSTALLED" ] && mv "$INSTALLED" "$PREVIOUS"
if ! mv "$STAGE" "$INSTALLED"; then
    [ -d "$PREVIOUS" ] && mv "$PREVIOUS" "$INSTALLED"
    echo "Install failed; restored the previous app" >&2
    exit 1
fi
rm -rf "$PREVIOUS"

codesign --verify --deep --strict "$INSTALLED"
SIGNATURE=$(codesign -dvv "$INSTALLED" 2>&1)
[[ "$SIGNATURE" == *$'\nAuthority=Tinycast Self-Signed\n'* ]] || { echo "Wrong signer" >&2; exit 1; }
HASH=$(shasum -a 256 "$BUILT/Contents/MacOS/Tinycast" | cut -d' ' -f1)
if [ "$HASH" != "$(shasum -a 256 "$INSTALLED/Contents/MacOS/Tinycast" | cut -d' ' -f1)" ]; then
    echo "Installed executable does not match the build" >&2
    exit 1
fi

open "$INSTALLED"
for _ in $(seq 1 40); do
    pgrep -f "$INSTALLED/Contents/MacOS/" >/dev/null && break
    sleep 0.25
done
pgrep -f "$INSTALLED/Contents/MacOS/" >/dev/null || { echo "Tinycast did not relaunch" >&2; exit 1; }

RECEIPT="build/personal-$VERSION-receipt.txt"
cat > "$RECEIPT" <<EOF
Installed $(date '+%Y-%m-%d %H:%M:%S')
Version: $VERSION ($(plist "$INSTALLED" TinycastUpstreamRelease), $(plist "$INSTALLED" TinycastUpstreamCommit))
Personal revision: $REVISION
Toolchain: $DEVELOPER_DIR
Executable SHA-256: $HASH
Previous app backup: ${BACKUP:-none}
EOF
printf 'Installed %s (%s) at %s\nReceipt: %s\n' "$VERSION" "${REVISION:0:7}" "$INSTALLED" "$RECEIPT"
