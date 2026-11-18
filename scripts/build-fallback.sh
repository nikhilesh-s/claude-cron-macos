#!/bin/bash
# Builds "build/Claude Cron.app" from the AppKit fallback source using the
# Command Line Tools only (no Xcode needed).
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/Claude Cron.app"
mkdir -p "$APP/Contents/MacOS"
clang -fobjc-arc ClaudeCron/ClaudeCronFallback.m \
  -o "$APP/Contents/MacOS/Claude Cron" \
  -framework Cocoa -framework ApplicationServices -mmacosx-version-min=13.0
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Claude Cron</string>
  <key>CFBundleExecutable</key><string>Claude Cron</string>
  <key>CFBundleIdentifier</key><string>com.local.ClaudeCron</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
PLIST
echo "Built $APP"
