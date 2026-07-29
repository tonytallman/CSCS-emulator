# Bike Sensor Emulator

A cross-platform BLE Cycling Speed and Cadence Service (CSCS) emulator for iOS, iPadOS, and macOS, built with SwiftUI.

## Overview

Bike Sensor Emulator simulates a Bluetooth Low Energy cycling speed and cadence sensor, allowing developers, testers, and users to test CSCS-compatible apps without dedicated hardware. The app advertises itself as a standard BLE peripheral under the name **CSCS Emulator** and publishes simulated measurement data according to the Bluetooth SIG CSCS specification.

## Supported Platforms

- iOS
- iPadOS
- macOS

## Features

- Advertise a BLE CSCS peripheral with configurable speed and/or cadence support
- Two simulation modes: Random (default) and Manual
- Real-time speed (0–50 MPH) and cadence (0–200 RPM) control via sliders
- Supports one connected BLE central at a time
- On iPhone and iPad, continues BLE advertising while the app runs in the background
- Graceful error handling for Bluetooth unavailability, permission denials, Bluetooth turned off, and advertising failures

## User Interface

### Configuration Screen

Before starting the emulator, the user configures which metrics the simulated device will support:

| Control | Description |
| --- | --- |
| Speed Switch | Enables speed support |
| Cadence Switch | Enables cadence support |
| Start Emulator Button | Starts BLE advertising and simulation |

At least one metric (speed or cadence) must be enabled before the emulator can start. Once running, the supported metrics are locked until the emulator is stopped.

If Bluetooth permission is denied, Bluetooth is turned off, or BLE is unavailable on the device, the Start Emulator button is disabled and a message explains why. When permission is denied or Bluetooth is off, an **Open Settings** button helps the user fix the issue. On first launch, the system Bluetooth permission prompt still appears when the user taps Start.

### Running Screen

After starting, the app transitions to the running screen:

| Control | Description |
| --- | --- |
| Mode Segmented Control | Selects Random or Manual mode |
| Speed Slider | Controls simulated speed (visible only when speed was enabled) |
| Cadence Slider | Controls simulated cadence (visible only when cadence was enabled) |
| Stop Emulator Button | Stops BLE advertising and returns to configuration |

## Operating Modes

### Random

Default mode on start. Simulates a rider pedaling with naturally varying cadence. All sliders are disabled. Cadence follows a bounded random-walk model with a weak tendency toward 90 RPM, updating every simulation tick (10 Hz). Speed is derived from cadence using:

```
speed (MPH) = cadence (RPM) × 50 / 200
```

| Cadence (RPM) | Speed (MPH) |
| --- | --- |
| 45 | 11.25 |
| 90 | 22.5 |
| 135 | 33.75 |

### Manual

User-controlled speed and cadence. All visible sliders are enabled. Values remain constant until the user adjusts them.

## BLE Behavior

- **Advertised name:** `CSCS Emulator`
- **Service:** Cycling Speed and Cadence Service (Bluetooth SIG standard)
- **Published data:** Only the metrics selected during configuration (speed only, cadence only, or both)
- **Connections:** At most one BLE central at a time; additional connection requests are rejected
- **Background (iOS / iPadOS):** Continues advertising while backgrounded; the local name may be omitted from advertisement packets per CoreBluetooth behavior

## Architecture

The app follows MVVM with a clear separation of concerns:

| Layer | Components |
| --- | --- |
| UI | `RootView`, `ConfigurationView`, `RunningView` |
| View Models | `RootViewModel`, `ConfigurationViewModel`, `RunningViewModel` |
| Simulation | `SimulationEngine`, `RandomCadenceGenerator`, `ManualState`, `RandomState` |
| BLE | `CSCPeripheralManager`, `CSCSMeasurementEncoder`, `CentralSubscriptionTracker` |

Dependencies are wired at a single composition root (`AppContainer`) using constructor injection — no singletons or service locators.

## Technology Stack

- **UI:** SwiftUI
- **Architecture:** MVVM
- **BLE:** CoreBluetooth
- **Concurrency:** Swift Concurrency, `MainActor` for UI updates
- **Units:** Foundation `Measurement` (`UnitSpeed`, `UnitFrequency`) for type-safe speed and cadence values

## Project Structure

```
CSCSEmulator/
├── App/
│   ├── CSCSEmulatorApp.swift
│   └── AppContainer.swift
├── Models/
│   ├── Units.swift
│   ├── SimulatorConfiguration.swift
│   ├── SimulatorState.swift
│   ├── OperatingMode.swift
│   └── AppError.swift
├── Views/
│   ├── RootView.swift
│   ├── ConfigurationView.swift
│   └── RunningView.swift
├── ViewModels/
│   ├── RootViewModel.swift
│   ├── ConfigurationViewModel.swift
│   └── RunningViewModel.swift
├── Simulation/
│   ├── SimulationEngine.swift
│   ├── ManualState.swift
│   ├── RandomState.swift
│   └── RandomCadenceGenerator.swift
├── BLE/
│   ├── CSCPeripheralManager.swift
│   ├── CSCSMeasurementEncoder.swift
│   └── CentralSubscriptionTracker.swift
└── Resources/
    └── PrivacyInfo.xcprivacy
```

## App Store Submission

See [documentation/APP_STORE_SUBMISSION.md](documentation/APP_STORE_SUBMISSION.md) for metadata, privacy answers, and the manual submission checklist. Privacy policy: [documentation/PRIVACY_POLICY.md](documentation/PRIVACY_POLICY.md).

To prepare a new build, use the **`prepare-app-store-build`** Cursor skill (`.cursor/skills/prepare-app-store-build/`) or run the scripts under `scripts/` — bump build number, run unit tests, archive/export, and capture screenshots (named `Screenshot iPhone` / `Screenshot iPad` Simulators). Upload, App Review recording, and App Store Connect steps remain manual.

## Future Enhancements

- Wheel circumference and crank length configuration
- Sensor battery level simulation
- Save/load presets
- GPX route playback
- Recorded ride playback
- Automatic interval generation
- Multiple virtual sensors
- FTMS integration
- ANT+ support
- BLE connection status display
