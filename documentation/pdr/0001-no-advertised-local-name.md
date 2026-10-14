# 1. No advertised local name

- **Status**: Accepted
- **Date**: 2026-10-12
- **Affects**: SRS §4.1, §4.5; SDD §10, §11, §12

## Context

Earlier releases localized a Complete Local Name in BLE advertisement data. Centrals can discover CSCS peripherals by the 0x1816 service UUID without a friendly name.

## Decision

Set no advertised local name. Centrals find the emulator by the CSCS service UUID. Any name a scanner shows comes from the device.

## Consequences

**Positive**: Simpler advertisement payloads; no localized BLE name to maintain.

**Negative**: Some head units list unnamed devices as "Unknown" or hide them.

**Risks / follow-ups**: The next release's What's New should mention the change; `prepare-app-store-build` writes that at release time.
