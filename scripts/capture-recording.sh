#!/usr/bin/env bash
# Capture a screen recording demonstrating the app UI flow on Mac (default) or a
# physical iPhone. Uses CSCS_SCREENSHOT_MODE launch states (Configuration, then
# Running). On Mac, CSCS_DEMO_MODE keeps the app open instead of exporting a PNG.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-ios-device.sh
source "$ROOT/scripts/resolve-ios-device.sh"
PROJECT="$ROOT/CSCSEmulator"
OUT="$ROOT/build/recording"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
BUNDLE_ID="com.tallmansoftware.csc-emulator"
RECORDING_TARGET="${RECORDING_TARGET:-mac}"
CONFIGURATION_SECONDS="${CONFIGURATION_SECONDS:-5}"
RUNNING_SECONDS="${RUNNING_SECONDS:-12}"
WARMUP_SECONDS="${WARMUP_SECONDS:-2}"
TRANSITION_SECONDS="${TRANSITION_SECONDS:-1}"

mkdir -p "$OUT"

recording_duration() {
  echo $((WARMUP_SECONDS + CONFIGURATION_SECONDS + TRANSITION_SECONDS + RUNNING_SECONDS + TRANSITION_SECONDS))
}

terminate_mac_app() {
  pkill -x CSCSEmulator 2>/dev/null || true
  sleep 1
}

launch_mac_app() {
  local mode="$1"
  CSCS_DEMO_MODE=1 CSCS_SCREENSHOT_MODE="$mode" "$MAC_APP/Contents/MacOS/CSCSEmulator" &
  echo $!
}

record_mac() {
  local recording="$OUT/mac-flow.mov"
  local total
  total="$(recording_duration)"

  echo "Building macOS app (Debug)..."
  cd "$PROJECT"
  xcodebuild -scheme CSCSEmulator \
    -destination 'platform=macOS' \
    -configuration Debug build >/dev/null

  MAC_APP="$(find "$DERIVED" ! -path '*/Index.noindex/*' -path '*/Build/Products/Debug/CSCSEmulator.app' -maxdepth 8 | head -1)"
  if [[ -z "$MAC_APP" ]]; then
    echo "Could not locate built macOS app." >&2
    exit 1
  fi

  terminate_mac_app
  rm -f "$recording"

  echo "Recording Mac screen to $recording (${total}s)..."
  echo "Grant Screen Recording permission to Terminal/Cursor if prompted."
  screencapture -V "$total" -m -x -C "$recording" &
  local record_pid=$!

  cleanup() {
    terminate_mac_app
    if kill -0 "$record_pid" 2>/dev/null; then
      wait "$record_pid" 2>/dev/null || true
    fi
  }
  trap cleanup EXIT

  sleep "$WARMUP_SECONDS"

  echo "Launching Configuration screen..."
  launch_mac_app configuration >/dev/null
  sleep "$CONFIGURATION_SECONDS"

  terminate_mac_app

  echo "Launching Running screen..."
  launch_mac_app running >/dev/null
  sleep "$RUNNING_SECONDS"

  terminate_mac_app
  wait "$record_pid"
  trap - EXIT

  if [[ ! -f "$recording" ]]; then
    echo "Recording file was not created." >&2
    echo "Check System Settings → Privacy & Security → Screen Recording." >&2
    exit 1
  fi

  echo "Done. Recording saved to $recording"
  ls -lh "$recording"
}

launch_ios_app() {
  local mode="$1"
  xcrun devicectl device process launch \
    --device "$IOS_DEVICE" \
    --terminate-existing \
    -e "{\"CSCS_SCREENSHOT_MODE\": \"$mode\"}" \
    "$BUNDLE_ID" >/dev/null
}

record_ios() {
  local recording="$OUT/ios-flow.mp4"
  local total
  total="$(recording_duration)"

  echo "Building iOS device app (Debug)..."
  cd "$PROJECT"
  xcodebuild -scheme CSCSEmulator \
    -destination "platform=iOS,id=$IOS_DEVICE" \
    -configuration Debug build >/dev/null

  APP_PATH="$(find "$DERIVED" ! -path '*/Index.noindex/*' -path '*/Build/Products/Debug-iphoneos/CSCSEmulator.app' -maxdepth 8 | head -1)"
  if [[ -z "$APP_PATH" ]]; then
    echo "Could not locate built iOS app." >&2
    exit 1
  fi

  echo "Installing on $IOS_DEVICE..."
  xcrun devicectl device install app --device "$IOS_DEVICE" "$APP_PATH"

  rm -f "$recording"

  echo "Recording $IOS_DEVICE screen to $recording (${total}s)..."
  xcrun devicectl device capture screen-record \
    --device "$IOS_DEVICE" \
    --destination "$recording" \
    --duration "$total" \
    --codec h264 &
  local record_pid=$!

  sleep "$WARMUP_SECONDS"

  echo "Launching Configuration screen..."
  launch_ios_app configuration
  sleep "$CONFIGURATION_SECONDS"

  echo "Launching Running screen..."
  launch_ios_app running
  sleep "$RUNNING_SECONDS"

  wait "$record_pid" 2>/dev/null || true

  if [[ ! -f "$recording" ]]; then
    echo "Recording file was not created." >&2
    exit 1
  fi

  echo "Done. Recording saved to $recording"
  ls -lh "$recording"
}

case "$RECORDING_TARGET" in
  mac)
    record_mac
    ;;
  ios)
    record_ios
    ;;
  *)
    echo "Unknown RECORDING_TARGET: $RECORDING_TARGET (use mac or ios)" >&2
    exit 1
    ;;
esac
