#!/usr/bin/env bash
# Resolve a connected physical iPhone for xcodebuild and devicectl.
# Exports IOS_DEVICE (UDID). Override with IOS_DEVICE or IOS_DEVICE_ID.

set -euo pipefail

if [[ -n "${IOS_DEVICE:-}" ]]; then
  :
elif [[ -n "${IOS_DEVICE_ID:-}" ]]; then
  IOS_DEVICE="$IOS_DEVICE_ID"
else
  IOS_DEVICE="$(python3 - <<'PY'
import json
import subprocess
import sys
import tempfile
from pathlib import Path

with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as handle:
    json_path = Path(handle.name)

try:
    subprocess.run(
        ["xcrun", "devicectl", "list", "devices", "--json-output", str(json_path)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    devices = json.loads(json_path.read_text())["result"]["devices"]
finally:
    json_path.unlink(missing_ok=True)

for device in devices:
    hardware = device.get("hardwareProperties", {})
    connection = device.get("connectionProperties", {})
    if hardware.get("reality") != "physical":
        continue
    if hardware.get("deviceType") != "iPhone":
        continue
    if connection.get("tunnelState") != "connected":
        continue
    udid = hardware.get("udid")
    if udid:
        print(udid)
        sys.exit(0)

sys.stderr.write("No connected physical iPhone found. Set IOS_DEVICE to the device UDID.\n")
sys.exit(1)
PY
)"
fi

export IOS_DEVICE
