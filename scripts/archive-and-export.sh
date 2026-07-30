#!/usr/bin/env bash
# Archive and export Bike Sensor Emulator for App Store Connect (iOS).
# Produces a validated .ipa file ready for manual upload.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CSCSEmulator"
SCHEME="CSCSEmulator"
BUILD_DIR="$ROOT/build"
ARCHIVE_DIR="$BUILD_DIR/archives"
EXPORT_DIR="$BUILD_DIR/export"
IOS_ARCHIVE="$ARCHIVE_DIR/CSCSEmulator-iOS.xcarchive"
IOS_EXPORT="$EXPORT_DIR/ios"

mkdir -p "$ARCHIVE_DIR" "$IOS_EXPORT"

cd "$PROJECT"

echo "Archiving iOS (Release)..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath "$IOS_ARCHIVE" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=MYMYAX7K65

echo "Exporting iOS archive..."
xcodebuild -exportArchive \
  -archivePath "$IOS_ARCHIVE" \
  -exportPath "$IOS_EXPORT" \
  -exportOptionsPlist "$ROOT/scripts/ExportOptions-iOS.plist" \
  -allowProvisioningUpdates

echo ""
echo "Archive and export complete."
echo "  iOS archive: $IOS_ARCHIVE"
echo "  iOS export:  $IOS_EXPORT"
echo ""
echo "Exported artifacts:"
find "$EXPORT_DIR" -type f -name '*.ipa' -print
