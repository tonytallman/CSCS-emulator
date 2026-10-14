# 1. Adopt CSCServer for BLE peripheral

- **Status**: Accepted
- **Date**: 2026-10-12

## Context

The app implements its own Core Bluetooth peripheral for the Cycling Speed and Cadence Service. The BluetoothBikeSensorSwift package provides `CSCServer`, which owns GATT service construction, measurement encoding, outbound backpressure, and the SC Control Point.

## Decision

- Depend on the `CSCServer` product from BluetoothBikeSensorSwift, using Up to Next Major Version from 1.1.0, linked to the app target only.
- Bridge the library through a single adaptor type behind a `MeasurementServer` protocol.
- Build a new `Server` on each Start, fed by one combined revolution stream per session.
- Keep an app-owned Bluetooth state monitor, because `CSCServer` has no authorization or power-state API and suspends silently on radio loss.
- Each advertising session awaits the previous session's `stop()`, because the library allows concurrent servers.

## Consequences

**Positive**: Less peripheral code to maintain; encoding and control-point behavior stay aligned with the shared library.

**Negative**: Two `CBPeripheralManager` instances exist while the emulator is running (monitor plus library).

**Risks / follow-ups**: The app stops on Bluetooth loss instead of relying on silent suspend. User-facing errors map from live Bluetooth state; `ServerError` from failed starts is logged only. `Package.resolved` pins the resolved package version.
