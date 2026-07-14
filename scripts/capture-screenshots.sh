#!/usr/bin/env bash
# Capture App Store screenshots for CSCS Emulator.
# Requires Xcode and the iOS Simulator. Mac screenshots are exported by the
# Debug build itself (no Screen Recording permission required).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CSCSEmulator"
OUT="$ROOT/documentation/screenshots"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
BUNDLE_ID="com.tallmansoftware.csc-emulator"

mkdir -p "$OUT"

echo "Building iOS Simulator app..."
cd "$PROJECT"
xcodebuild -scheme CSCSEmulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -configuration Debug build >/dev/null

APP_PATH="$(find "$DERIVED" -path '*/Debug-iphonesimulator/CSCSEmulator.app' -maxdepth 6 | head -1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Could not locate built iOS app." >&2
  exit 1
fi

capture_ios() {
  local device_name="$1"
  local prefix="$2"
  local device_id
  device_id="$(xcrun simctl list devices available | rg "$device_name" | head -1 | rg -o '[A-F0-9-]{36}')"

  echo "Capturing $prefix on $device_name ($device_id)..."
  xcrun simctl boot "$device_id" 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$device_id"
  xcrun simctl install "$device_id" "$APP_PATH"

  SIMCTL_CHILD_CSCS_SCREENSHOT_MODE=configuration xcrun simctl launch "$device_id" "$BUNDLE_ID" >/dev/null
  sleep 3
  xcrun simctl io "$device_id" screenshot "$OUT/${prefix}-configuration.png"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null || true

  SIMCTL_CHILD_CSCS_SCREENSHOT_MODE=running xcrun simctl launch "$device_id" "$BUNDLE_ID" >/dev/null
  sleep 3
  xcrun simctl io "$device_id" screenshot "$OUT/${prefix}-running.png"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null || true

  # iPhone 16/17 Pro Max simulators capture at 1320×2868 (6.9" display). App Store
  # Connect's 6.5" iPhone slot requires 1284×2778 or 1242×2688.
  if [[ "$prefix" == iphone ]]; then
    sips -z 2778 1284 "$OUT/${prefix}-configuration.png" --out "$OUT/${prefix}-configuration.png" >/dev/null
    sips -z 2778 1284 "$OUT/${prefix}-running.png" --out "$OUT/${prefix}-running.png" >/dev/null
  fi
}

capture_ios "iPhone 16 Pro Max" iphone
capture_ios "iPad Pro 13-inch (M4)" ipad

echo "Building macOS app..."
xcodebuild -scheme CSCSEmulator -destination 'platform=macOS' -configuration Debug build >/dev/null
MAC_APP="$(find "$DERIVED" -path '*/Debug/CSCSEmulator.app' -maxdepth 6 | head -1)"

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
