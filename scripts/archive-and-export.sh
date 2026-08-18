#!/usr/bin/env bash
# Archive Bike Sensor Emulator for App Store Connect (iOS).
# Writes the Release .xcarchive directly into Xcode Organizer for Validate / Distribute.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CSCSEmulator"
SCHEME="CSCSEmulator"
XCODE_ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"

organizer_archive_name() {
  local month day year hour minute ampm
  month=$(date +%m | sed 's/^0//')
  day=$(date +%d | sed 's/^0//')
  year=$(date +%y)
  hour=$(date +%I | sed 's/^0//')
  minute=$(date +%M)
  ampm=$(date +%p)
  if [[ -z "$hour" ]]; then
    hour=12
  fi
  printf 'CSCSEmulator %s-%s-%s, %s.%s %s.xcarchive' "$month" "$day" "$year" "$hour" "$minute" "$ampm"
}

ORGANIZER_ARCHIVE_NAME="$(organizer_archive_name)"
ORGANIZER_ARCHIVE_PATH="$XCODE_ARCHIVES_DIR/$ORGANIZER_ARCHIVE_NAME"

if [[ -e "$ORGANIZER_ARCHIVE_PATH" ]]; then
  ORGANIZER_ARCHIVE_NAME="$(organizer_archive_name | sed 's/\.xcarchive$//') $(date +%S).xcarchive"
  ORGANIZER_ARCHIVE_PATH="$XCODE_ARCHIVES_DIR/$ORGANIZER_ARCHIVE_NAME"
fi

mkdir -p "$XCODE_ARCHIVES_DIR"

cd "$PROJECT"

echo "Archiving iOS (Release) into Xcode Organizer..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath "$ORGANIZER_ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=MYMYAX7K65

echo ""
echo "Archive complete."
echo "  Xcode Organizer: $ORGANIZER_ARCHIVE_PATH"
echo ""
echo "Open Xcode → Window → Organizer to Validate App or Distribute App."
