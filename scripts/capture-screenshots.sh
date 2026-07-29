#!/usr/bin/env bash
# Capture App Store screenshots for Bike Sensor Emulator.
# iPhone / iPad: named Simulators (Screenshot iPhone, Screenshot iPad).
# Mac: exported by the Debug build itself.
#
# Before running: apply the temporary Simulator Bluetooth-availability bypass in
# CSCPeripheralManager (see prepare-app-store-build skill Step 4). Undo it after.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CSCSEmulator"
OUT="$ROOT/documentation/screenshots"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
BUNDLE_ID="com.tallmansoftware.csc-emulator"
# Short settles often capture SpringBoard instead of the app after simctl launch.
SCREENSHOT_SETTLE_SECONDS="${SCREENSHOT_SETTLE_SECONDS:-6}"
IPHONE_SIMULATOR_NAME="Screenshot iPhone"
IPAD_SIMULATOR_NAME="Screenshot iPad"

mkdir -p "$OUT"

resolve_sim_udid() {
  local device_name="$1"
  local device_id
  device_id="$(xcrun simctl list devices available | rg "$device_name" | head -1 | rg -o '[A-F0-9-]{36}' || true)"
  if [[ -z "$device_id" ]]; then
    echo "Simulator not found: $device_name" >&2
    echo "Create it in Xcode → Window → Devices and Simulators." >&2
    exit 1
  fi
  printf '%s\n' "$device_id"
}

build_ios_simulator_app() {
  echo "Building iOS Simulator app (generic destination)..."
  cd "$PROJECT"
  xcodebuild -scheme CSCSEmulator \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Debug build >/dev/null

  local app_path
  app_path="$(find "$DERIVED" ! -path '*/Index.noindex/*' -path '*/Build/Products/Debug-iphonesimulator/CSCSEmulator.app' -maxdepth 8 | head -1)"
  if [[ -z "$app_path" ]]; then
    echo "Could not locate built iOS Simulator app." >&2
    exit 1
  fi
  printf '%s\n' "$app_path"
}

capture_ios_simulator() {
  local device_name="$1"
  local prefix="$2"
  local app_path="$3"
  local device_id
  device_id="$(resolve_sim_udid "$device_name")"

  echo "Capturing $prefix on $device_name ($device_id)..."
  xcrun simctl boot "$device_id" 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$device_id"
  sleep 2
  xcrun simctl install "$device_id" "$app_path"

  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  sleep 1
  SIMCTL_CHILD_CSCS_SCREENSHOT_MODE=configuration \
    xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null
  sleep "$SCREENSHOT_SETTLE_SECONDS"
  xcrun simctl io "$device_id" screenshot "$OUT/${prefix}-configuration.png"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true

  sleep 1
  SIMCTL_CHILD_CSCS_SCREENSHOT_MODE=running \
    xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null
  sleep "$SCREENSHOT_SETTLE_SECONDS"
  xcrun simctl io "$device_id" screenshot "$OUT/${prefix}-running.png"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true

  echo "Captured $prefix (configuration, running) from $device_name"
}

SIM_APP="$(build_ios_simulator_app)"
echo "App: $SIM_APP"

capture_ios_simulator "$IPHONE_SIMULATOR_NAME" iphone "$SIM_APP"
capture_ios_simulator "$IPAD_SIMULATOR_NAME" ipad "$SIM_APP"

# App Store Connect 6.5" iPhone slot accepts 1284×2778 or 1242×2688.
sips -z 2778 1284 "$OUT/iphone-configuration.png" --out "$OUT/iphone-configuration.png" >/dev/null
sips -z 2778 1284 "$OUT/iphone-running.png" --out "$OUT/iphone-running.png" >/dev/null

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
