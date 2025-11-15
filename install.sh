#!/bin/bash

# Check if /Applications is writable, otherwise fallback to ~/Applications
if [ -w "/Applications" ]; then
    APP_DIR="/Applications"
    echo "[Info] Installing Roblox system-wide in /Applications"
else
    APP_DIR="$HOME/Applications"
    echo "[Info] Installing Roblox locally in ~/Applications"
    mkdir -p "$APP_DIR"
fi

DYLIB_URL="https://raw.githubusercontent.com/RSDTestAccount/Cryptic-Mac-Internal-Assets/refs/heads/main/libCryptic.dylib"
MODULES_URL="https://raw.githubusercontent.com/RSDTestAccount/Cryptic-Mac-Internal-Assets/refs/heads/main/Resources.zip"
UI_URL="https://raw.githubusercontent.com/RSDTestAccount/Cryptic-Mac-Internal-Assets/refs/heads/main/Cryptic.zip"

echo "[Cryptic Mac Installer] Starting installation..."

#echo "[1/6] Fetching Roblox version..."
#json=$(curl -s "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
#version=$(echo "$json" | grep -o '"clientVersionUpload":"[^"]*' | grep -o '[^"]*$')

#if [ -z "$version" ]; then
#    echo "[Error] Could not fetch Roblox version. Aborting."
#    exit 1
#fi

if pgrep -x "RobloxPlayer" >/dev/null; then
    echo "[Info] Stopping running Roblox instance..."
    pkill -9 RobloxPlayer
fi

if pgrep -x "Cryptic" >/dev/null; then
    echo "[Info] Stopping running UI instance..."
    pkill -9 Cryptic
fi

if [ -d "$APP_DIR/Roblox.app" ]; then
    echo "[Info] Removing previous Roblox installation..."
    rm -rf "$APP_DIR/Roblox.app"
fi

if [ -d "$APP_DIR/Cryptic.app" ]; then
    echo "[Info] Removing previous UI installation..."
    rm -rf "$APP_DIR/Cryptic.app"
fi

echo "[1/6] Downloading Roblox"
curl -s -L "https://setup.rbxcdn.com/mac/version-6e8186c3f6ce4303-RobloxPlayer.zip" -o "$APP_DIR/RobloxPlayer.zip"

echo "[2/6] Installing Roblox..."
unzip -o -q "$APP_DIR/RobloxPlayer.zip" -d "$APP_DIR"
mv "$APP_DIR/RobloxPlayer.app" "$APP_DIR/Roblox.app"
rm "$APP_DIR/RobloxPlayer.zip"
xattr -cr "$APP_DIR/Roblox.app"

echo "[3/6] Downloading Cryptic Mac dylib..."
curl -s -L "$DYLIB_URL" -o "$APP_DIR/libCryptic.dylib"
mv "$APP_DIR/libCryptic.dylib" "$APP_DIR/Roblox.app/Contents/Resources/libCryptic.dylib"

rm -rf "$APP_DIR/Roblox.app/Contents/MacOS/RobloxPlayerInstaller.app"

echo "[4/6] Downloading Resources..."
curl -s -L "$MODULES_URL" -o "$APP_DIR/Resources.zip"
unzip -o -q "$APP_DIR/Resources.zip" -d "$APP_DIR"
rm "$APP_DIR/Resources.zip"

echo "[5/6] Patching Roblox..."
"$APP_DIR/Resources/Patcher" \
    "$APP_DIR/Roblox.app/Contents/Resources/libCryptic.dylib" \
    "$APP_DIR/Roblox.app/Contents/MacOS/libmimalloc.3.dylib" \
    --strip-codesig --all-yes

mv "$APP_DIR/Roblox.app/Contents/MacOS/libmimalloc.3.dylib_patched" \
   "$APP_DIR/Roblox.app/Contents/MacOS/libmimalloc.3.dylib"

codesign --force --deep --sign - "$APP_DIR/Roblox.app"

echo "[6/6] Downloading UI..."
curl -s -L "$UI_URL" -o "$APP_DIR/UI.zip"
unzip -o -q "$APP_DIR/UI.zip" -d "$APP_DIR"
rm "$APP_DIR/UI.zip"

echo "[Done] Cryptic Mac installed successfully."
echo "[Info] Launching Roblox and the UI..."
open "$APP_DIR/Roblox.app"
open "$APP_DIR/Cryptic.app"

exit 0