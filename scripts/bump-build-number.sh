#!/usr/bin/env bash
# Increment CURRENT_PROJECT_VERSION across all targets in the Xcode project.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$ROOT/CSCSEmulator/CSCSEmulator.xcodeproj/project.pbxproj"

if [[ ! -f "$PBXPROJ" ]]; then
  echo "Could not find project file: $PBXPROJ" >&2
  exit 1
fi

current="$(rg -o 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" | head -1 | rg -o '[0-9]+')"
if [[ -z "$current" ]]; then
  echo "Could not read CURRENT_PROJECT_VERSION from $PBXPROJ" >&2
  exit 1
fi

next=$((current + 1))

echo "Bumping build number: $current -> $next"

perl -pi -e "s/CURRENT_PROJECT_VERSION = \\d+;/CURRENT_PROJECT_VERSION = $next;/g" "$PBXPROJ"

updated_values="$(rg -o 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" | sort -u)"
if [[ "$(printf '%s\n' "$updated_values" | wc -l | tr -d ' ')" -ne 1 ]]; then
  echo "Build number verification failed; found mismatched values:" >&2
  printf '%s\n' "$updated_values" >&2
  exit 1
fi

if ! printf '%s\n' "$updated_values" | rg -q "CURRENT_PROJECT_VERSION = $next;"; then
  echo "Build number verification failed; expected $next everywhere." >&2
  exit 1
fi

echo "Updated all CURRENT_PROJECT_VERSION entries to $next in project.pbxproj"
echo "MARKETING_VERSION unchanged (bump manually for a new App Store version)."
