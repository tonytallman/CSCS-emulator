# CSCS Emulator Software Design Document

## 1. Purpose

This document describes the software architecture and implementation approach for the CSCS Emulator application.

The application simulates a Bluetooth Low Energy (BLE) Cycling Speed and Cadence Service (CSCS) peripheral and allows users to control the transmitted data through a graphical user interface.

This document is intended to guide implementation and future maintenance.

---

# 2. Design Goals

## 2.1 Simplicity

The application should remain simple enough for a single developer to maintain.

## 2.2 Cross-Platform Support

A single codebase shall support:

* iOS
* iPadOS
* macOS

## 2.3 Separation of Concerns

The following responsibilities shall be isolated:

* User Interface
* Simulation Logic
* BLE Peripheral Management
* CSCS Encoding

## 2.4 Extensibility

The design should allow future additions such as:

* Multiple virtual sensors
* GPX playback
* ANT+ support
* Additional BLE services
* Sensor battery simulation

without requiring major architectural changes.

---

# 3. High-Level Architecture

```text
+----------------------+
| SwiftUI Views        |
+----------+-----------+
           |
           v
+----------------------+
| View Models          |
+----------+-----------+
           |
           v
+----------------------+
| Simulation Engine    |
+----------+-----------+
           |
           +----------------+
           |                |
           v                v
+----------------+   +----------------+
| BLE Peripheral |   | State Storage  |
+----------------+   +----------------+
           |
           v
+----------------------+
| CoreBluetooth        |
+----------------------+
```

The user interface communicates only with view models.

View models communicate with the simulation engine.

The BLE subsystem observes simulator state and publishes measurement updates.

---

# 4. Technology Stack

## UI Framework

* SwiftUI

## Application Architecture

* MVVM

## BLE Framework

* CoreBluetooth

## Concurrency

* Swift Concurrency
* MainActor for UI updates

## Platforms

* iOS
* iPadOS
* macOS

---

# 5. Module Design

## 5.1 User Interface Layer

### Responsibilities

* Display configuration controls
* Display simulator controls
* Display connection status
* Display current speed and cadence
* Display error messages

### Components

```text
ConfigurationView
RunningView
```

The views should contain minimal business logic.

---

## 5.2 View Model Layer

### Responsibilities

* Manage UI state
* Validate user input
* Coordinate simulator startup and shutdown
* Coordinate BLE operations

### Components

```text
ConfigurationViewModel
RunningViewModel
```

The view models act as the boundary between UI and application logic.

---

## 5.3 Simulation Layer

### Responsibilities

* Maintain current simulator values
* Execute mode-specific behavior
* Generate speed and cadence updates
* Provide a unified state model

### Components

```text
SimulationEngine
RandomCadenceGenerator
CoastingModel
```

---

# 6. Simulator State Model

## SimulatorConfiguration

```swift
struct SimulatorConfiguration {
    let supportsSpeed: Bool
    let supportsCadence: Bool
}
```

Configuration is immutable while the simulator is running.

---

## OperatingMode

```swift
enum OperatingMode {
    case pedaling
    case coasting
    case random
}
```

---

## SimulatorState

```swift
struct SimulatorState {
    var mode: OperatingMode

    var speedMPH: Double
    var cadenceRPM: Double

    var supportsSpeed: Bool
    var supportsCadence: Bool

    var isRunning: Bool
}
```

The Simulation Engine owns this state.

---

# 7. Simulation Engine

## Responsibilities

* Maintain current state
* Execute simulation updates
* Publish state changes
* Apply operating mode rules

## Update Frequency

The simulation engine shall execute at a fixed interval.

Initial target:

```text
10 Hz
```

This interval may be adjusted in future versions.

---

# 8. Pedaling Mode

## Behavior

* User controls speed slider
* User controls cadence slider
* Values remain fixed until changed

No automatic updates occur.

---

# 9. Coasting Mode

## Entry Actions

Immediately upon entering coasting mode:

```text
cadenceRPM = 0
```

The current speed value is retained.

## Update Behavior

Each simulation tick:

```text
speedRPM = decay(speedRPM)
```

until speed reaches zero.

### Initial Decay Algorithm

The initial implementation may use:

```text
speed = speed * 0.98
```

per simulation tick.

The decay model may be refined later without affecting architecture.

---

# 10. Random Mode

## Overview

Random mode simulates a rider pedaling continuously with natural cadence variations.

The user cannot directly manipulate speed or cadence.

---

## Internal Cadence State

Random mode maintains an internal cadence value.

This cadence value exists even when cadence support is disabled.

Example:

```text
supportsSpeed = true
supportsCadence = false
```

The simulator still generates cadence internally.

The cadence is simply not displayed or published.

---

## Cadence Generation

The cadence generator shall implement a bounded random walk.

Example update:

```text
cadence =
    cadence
    + randomDelta
    + biasToward90
```

Where:

```text
randomDelta ∈ [-2,+2]
biasToward90 = (90 - cadence) * 0.02
```

The exact constants may be tuned.

---

## Speed Generation

Speed is derived from cadence.

```text
speedMPH = cadenceRPM * 20.0 / 90.0
```

---

# 11. BLE Subsystem

## Responsibilities

* Advertise the CSCS service
* Accept central connections
* Publish measurements
* Track subscriptions
* Enforce connection limits

---

## Device Name

Advertised local name:

```text
CSCS emulator
```

---

## Service Configuration

The application shall expose:

```text
Cycling Speed and Cadence Service
```

The implementation shall follow the Bluetooth SIG CSCS specification.

---

## Measurement Characteristic

Measurement packets shall be generated from the current SimulatorState.

The packet encoder shall be isolated from BLE transport logic.

---

## Flag Selection

### Speed Only

```text
Wheel Data Present = true
Crank Data Present = false
```

### Cadence Only

```text
Wheel Data Present = false
Crank Data Present = true
```

### Speed + Cadence

```text
Wheel Data Present = true
Crank Data Present = true
```

---

# 12. Connection Management

## Supported Connections

Maximum simultaneous central connections:

```text
1
```

---

## Connection Policy

If no central is connected:

```text
accept connection
```

If a central is already connected:

```text
reject additional connection
```

---

## UI Display

The running screen shall display:

```text
Not Connected
Connected
```

No additional central details are required.

---

# 13. CSCS Encoder

## Responsibilities

Convert simulator state into valid CSCS measurement packets.

### Inputs

```swift
SimulatorState
```

### Outputs

```swift
Data
```

The encoder should contain no CoreBluetooth dependencies.

This allows independent unit testing.

---

# 14. Error Handling

Errors shall be surfaced through a shared application error model.

Example categories:

```swift
enum AppError {
    case bluetoothUnavailable
    case bluetoothDisabled
    case advertisingFailed
    case connectionFailed
    case internalError
}
```

Errors should be user-visible and logged.

---

# 15. Suggested Project Structure

```text
CSCSEmulator/

├── App/
│   └── CSCSEmulatorApp.swift
│
├── Models/
│   ├── SimulatorConfiguration.swift
│   ├── SimulatorState.swift
│   ├── OperatingMode.swift
│   └── AppError.swift
│
├── Views/
│   ├── ConfigurationView.swift
│   └── RunningView.swift
│
├── ViewModels/
│   ├── ConfigurationViewModel.swift
│   └── RunningViewModel.swift
│
├── Simulation/
│   ├── SimulationEngine.swift
│   ├── RandomCadenceGenerator.swift
│   └── CoastingModel.swift
│
├── BLE/
│   ├── CSCPeripheralManager.swift
│   ├── CSCSMeasurementEncoder.swift
│   └── BLEConnectionManager.swift
│
└── Resources/
```

---

# 16. Future Enhancements

The architecture should support future additions including:

* Multiple central connections
* Multiple virtual sensors
* Background operation
* Sensor battery simulation
* GPX route playback
* Ride recording and playback
* ANT+ support
* Additional BLE services
* Remote control APIs

without requiring significant restructuring of existing modules.
