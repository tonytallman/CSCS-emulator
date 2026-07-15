#!/usr/bin/env bash
# Run CSCSEmulator unit tests on iOS Simulator and macOS. Exits non-zero on failure.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CSCSEmulator"
SCHEME="CSCSEmulator"
TEST_TARGET="-only-testing:CSCSEmulatorTests"

cd "$PROJECT"

echo "Running unit tests on iOS Simulator..."
xcodebuild test \
  -scheme "$SCHEME" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.5' \
  $TEST_TARGET

echo "Running unit tests on macOS..."
xcodebuild test \
  -scheme "$SCHEME" \
  -destination 'platform=macOS' \
  $TEST_TARGET

echo "All unit tests passed."
