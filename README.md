# CSCS Emulator

A cross-platform BLE Cycling Speed and Cadence Service (CSCS) emulator for iOS, iPadOS, and macOS, built with SwiftUI.

## Overview

CSCS Emulator simulates a Bluetooth Low Energy cycling speed and cadence sensor, allowing developers, testers, and users to test CSCS-compatible apps without dedicated hardware. The app advertises itself as a standard BLE peripheral under the name **CSCS emulator** and publishes simulated measurement data according to the Bluetooth SIG CSCS specification.

## Supported Platforms

- iOS
- iPadOS
- macOS

## Features

- Advertise a BLE CSCS peripheral with configurable speed and/or cadence support
- Three simulation modes: Pedaling, Coasting, and Random
- Real-time speed (0–50 MPH) and cadence (0–200 RPM) control via sliders
- Supports one connected BLE central at a time
- Graceful error handling for Bluetooth unavailability, permission denials, and advertising failures

## User Interface

### Configuration Screen

Before starting the emulator, the user configures which metrics the simulated device will support:

| Control | Description |
| --- | --- |
| Speed Switch | Enables speed support |
| Cadence Switch | Enables cadence support |
| Start Emulator Button | Starts BLE advertising and simulation |

At least one metric (speed or cadence) must be enabled before the emulator can start. Once running, the supported metrics are locked until the emulator is stopped.

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

- **Advertised name:** `CSCS emulator`
- **Service:** Cycling Speed and Cadence Service (Bluetooth SIG standard)
- **Published data:** Only the metrics selected during configuration (speed only, cadence only, or both)
- **Connections:** At most one BLE central at a time; additional connection requests are rejected

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
```

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
- Background operation
- BLE connection status display
