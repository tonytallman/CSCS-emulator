# Bike Sensor Emulator

A cross-platform BLE Cycling Speed and Cadence Service (CSCS) emulator for iOS, iPadOS, and macOS, built with SwiftUI.

## Overview

Bike Sensor Emulator simulates a Bluetooth Low Energy cycling speed and cadence sensor, allowing developers, testers, and users to test CSCS-compatible apps without dedicated hardware. The app advertises itself as a standard BLE peripheral under the name **Bike Sensor Emulator** and publishes simulated measurement data according to the Bluetooth SIG CSCS specification.

## Supported Platforms

- iOS
- iPadOS
- macOS

## Features

- Advertise a BLE CSCS peripheral with configurable speed and/or cadence support
- Three simulation modes: Pedaling, Coasting, and Random
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
| Mode Segmented Control | Selects Pedaling, Coasting, or Random mode |
| Speed Slider | Controls simulated speed (visible only when speed was enabled) |
| Cadence Slider | Controls simulated cadence (visible only when cadence was enabled) |
| Stop Emulator Button | Stops BLE advertising and returns to configuration |

## Operating Modes

### Pedaling

Active cycling. All visible sliders are enabled. Values remain constant until the user adjusts them.

### Coasting

Rider has stopped pedaling. All sliders are disabled. Cadence immediately drops to 0 RPM and speed decays monotonically toward zero.

### Random

Simulates a rider pedaling with naturally varying cadence. All sliders are disabled. Cadence follows a bounded random-walk model with a weak tendency toward 90 RPM, updating once per second. Speed is derived from cadence using:

```
speed (MPH) = cadence (RPM) × 20 / 90
```

| Cadence (RPM) | Speed (MPH) |
| --- | --- |
| 45 | 10.0 |
| 90 | 20.0 |
| 135 | 30.0 |

## BLE Behavior

- **Advertised name:** `Bike Sensor Emulator`
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
| Simulation | `SimulationEngine`, `RandomCadenceGenerator`, `CoastingModel` |
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
│   ├── PedalingState.swift
│   ├── CoastingState.swift
│   ├── RandomState.swift
│   ├── RandomCadenceGenerator.swift
│   └── CoastingModel.swift
├── BLE/
│   ├── CSCPeripheralManager.swift
│   ├── CSCSMeasurementEncoder.swift
│   └── CentralSubscriptionTracker.swift
└── Resources/
    └── PrivacyInfo.xcprivacy
```

## App Store Submission

See [documentation/APP_STORE_SUBMISSION.md](documentation/APP_STORE_SUBMISSION.md) for metadata, privacy answers, and the manual submission checklist. Privacy policy: [documentation/PRIVACY_POLICY.md](documentation/PRIVACY_POLICY.md).

To prepare a new build, use the **`prepare-app-store-build`** Cursor skill (`.cursor/skills/prepare-app-store-build/`) or run the scripts under `scripts/` — bump build number, run unit tests, archive/export, and capture screenshots (iPhone requires a physical device). Upload, App Review recording, and App Store Connect steps remain manual.

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
