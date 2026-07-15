#!/usr/bin/env bash
# Capture App Store screenshots for CSCS Emulator.
# iPhone: physical device (Simulator cannot represent Bluetooth permission UI).
# iPad: iOS Simulator. Mac: exported by the Debug build itself.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-ios-device.sh
source "$ROOT/scripts/resolve-ios-device.sh"
PROJECT="$ROOT/CSCSEmulator"
OUT="$ROOT/documentation/screenshots"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
BUNDLE_ID="com.tallmansoftware.csc-emulator"
SCREENSHOT_SETTLE_SECONDS="${SCREENSHOT_SETTLE_SECONDS:-3}"

mkdir -p "$OUT"

launch_ios_device_app() {
  local mode="$1"
  xcrun devicectl device process launch \
    --device "$IOS_DEVICE" \
    --terminate-existing \
    -e "{\"CSCS_SCREENSHOT_MODE\": \"$mode\"}" \
    "$BUNDLE_ID" >/dev/null
}

capture_iphone_device() {
  echo "Building iOS device app (Debug)..."
  cd "$PROJECT"
  xcodebuild -scheme CSCSEmulator \
    -destination "platform=iOS,id=$IOS_DEVICE" \
    -configuration Debug build >/dev/null

  local app_path
  app_path="$(find "$DERIVED" ! -path '*/Index.noindex/*' -path '*/Build/Products/Debug-iphoneos/CSCSEmulator.app' -maxdepth 8 | head -1)"
  if [[ -z "$app_path" ]]; then
    echo "Could not locate built iOS device app." >&2
    exit 1
  fi

  echo "Installing on $IOS_DEVICE..."
  xcrun devicectl device install app --device "$IOS_DEVICE" "$app_path"

  echo "Capturing iPhone screenshots on $IOS_DEVICE..."
  echo "Ensure Bluetooth permission is granted on the device (Settings → CSCS Emulator)."

  launch_ios_device_app configuration
  sleep "$SCREENSHOT_SETTLE_SECONDS"
  xcrun devicectl device capture screenshot \
    --device "$IOS_DEVICE" \
    --destination "$OUT/iphone-configuration.png"

  launch_ios_device_app running
  sleep "$SCREENSHOT_SETTLE_SECONDS"
  xcrun devicectl device capture screenshot \
    --device "$IOS_DEVICE" \
    --destination "$OUT/iphone-running.png"

  # App Store Connect 6.5" iPhone slot accepts 1284×2778 or 1242×2688.
  sips -z 2778 1284 "$OUT/iphone-configuration.png" --out "$OUT/iphone-configuration.png" >/dev/null
  sips -z 2778 1284 "$OUT/iphone-running.png" --out "$OUT/iphone-running.png" >/dev/null

  echo "Captured iPhone (configuration, running) from $IOS_DEVICE"
}

capture_ios_simulator() {
  local device_name="$1"
  local prefix="$2"

  echo "Building iOS Simulator app..."
  cd "$PROJECT"
  xcodebuild -scheme CSCSEmulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.5' \
    -configuration Debug build >/dev/null

  local app_path
  app_path="$(find "$DERIVED" ! -path '*/Index.noindex/*' -path '*/Build/Products/Debug-iphonesimulator/CSCSEmulator.app' -maxdepth 8 | head -1)"
  if [[ -z "$app_path" ]]; then
    echo "Could not locate built iOS Simulator app." >&2
    exit 1
  fi

  local device_id
  device_id="$(xcrun simctl list devices available | rg "$device_name" | head -1 | rg -o '[A-F0-9-]{36}')"

  echo "Capturing $prefix on $device_name ($device_id)..."
  xcrun simctl boot "$device_id" 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$device_id"
  xcrun simctl install "$device_id" "$app_path"

  SIMCTL_CHILD_CSCS_SCREENSHOT_MODE=configuration xcrun simctl launch "$device_id" "$BUNDLE_ID" >/dev/null
  sleep "$SCREENSHOT_SETTLE_SECONDS"
  xcrun simctl io "$device_id" screenshot "$OUT/${prefix}-configuration.png"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null || true

  SIMCTL_CHILD_CSCS_SCREENSHOT_MODE=running xcrun simctl launch "$device_id" "$BUNDLE_ID" >/dev/null
  sleep "$SCREENSHOT_SETTLE_SECONDS"
  xcrun simctl io "$device_id" screenshot "$OUT/${prefix}-running.png"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null || true
}

capture_iphone_device
capture_ios_simulator "iPad Pro 13-inch (M4)" ipad

echo "Building macOS app..."
cd "$PROJECT"
xcodebuild -scheme CSCSEmulator -destination 'platform=macOS' -configuration Debug build >/dev/null
MAC_APP="$(find "$DERIVED" ! -path '*/Index.noindex/*' -path '*/Build/Products/Debug/CSCSEmulator.app' -maxdepth 8 | head -1)"

capture_mac() {
  local mode="$1"
  local file="$2"
  pkill -x CSCSEmulator 2>/dev/null || true
  sleep 1
  local output
  output="$(CSCS_SCREENSHOT_MODE="$mode" "$MAC_APP/Contents/MacOS/CSCSEmulator" 2>&1 || true)"
  local exported
  exported="$(printf '%s\n' "$output" | rg 'CSCS_SCREENSHOT_EXPORT=' | tail -1 | cut -d= -f2-)"
  if [[ -n "$exported" && -f "$exported" ]]; then
    cp "$exported" "$file"
    sips -z 2027 1280 "$file" --out "$file" >/dev/null
    echo "Captured Mac ($mode): $file"
  else
    echo "Mac screenshot export failed for $mode" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
}

capture_mac configuration "$OUT/mac-configuration.png"
capture_mac running "$OUT/mac-running.png"

echo "Done. Screenshots in $OUT:"
ls -la "$OUT"
