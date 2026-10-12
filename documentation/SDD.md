# CSCS BLE Emulator Software Design Document

## 1. Purpose

This document describes the software architecture and implementation approach for the CSCS BLE Emulator application.

The application simulates a Bluetooth Low Energy (BLE) Cycling Speed and Cadence Service (CSCS) peripheral and allows users to control the transmitted data through a graphical user interface.

This document is intended to guide implementation and future maintenance.

---

# 2. Design Goals

## 2.1 Simplicity

The application should remain simple enough for a single developer to maintain.

## 2.2 Cross-Platform Support

A single codebase using SwiftUI shall support:

* iOS
* iPadOS

The iPad app may also run on Apple Silicon Macs via “iPhone and iPad Apps on Mac.” There is no separate native macOS app.

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

`CSCSEmulatorApp` is the composition root. It instantiates `AppContainer` once and uses it to construct view models and long-lived collaborators. See section 3.1.

---

## 3.1 Dependency Injection

Dependencies are constructed and wired at a single composition root using a code-based container, not a string-key or dictionary registry.

### AppContainer

`AppContainer` holds factory methods that construct fully wired objects:

```swift
final class AppContainer {
    private let appStateStore: AppStateStore
    private let simulationEngine: SimulationEngine
    private let broadcaster: MeasurementBroadcaster

    init() { /* construct shared collaborators */ }

    func makeConfigurationViewModel() -> ConfigurationViewModel { ... }
    func makeRunningViewModel() -> RunningViewModel { ... }
    func makeRootViewModel() -> RootViewModel { ... }
}
```

Rationale:

* Compile-time safety without a DI framework
* Explicit construction order and object lifetimes
* Factory methods are more flexible than a simple dependency dictionary

### Lifetimes

Long-lived collaborators (`AppStateStore`, `SimulationEngine`, `MeasurementBroadcaster`) are stored properties on `AppContainer` so they can be shared (for example, `AppStateStore` is shared by all view models for navigation state, and the simulation engine is shared by the running view model and the measurement broadcaster).

### Injection Rules

* Components depend on protocol abstractions and receive collaborators via initializers.
* Views receive fully constructed view models from the container.
* No direct singleton access (e.g. `Type.shared`), global shared state, or service locators outside `AppContainer` and bootstrap code.

---

# 4. Technology Stack

## UI Framework

* SwiftUI

## Application Architecture

* MVVM

## BLE Framework

* CoreBluetooth (Bluetooth state monitoring in the app)
* [BluetoothBikeSensorSwift](https://github.com/tonytallman/BluetoothBikeSensorSwift) `CSCServer` (GATT peripheral and measurement encoding)

## Concurrency

* Swift Concurrency
* MainActor for UI updates

## Units

* Foundation `Measurement` for unit-safe speed and cadence quantities

## Platforms

* iOS
* iPadOS
* Apple Silicon Mac (via the iPad app on Mac)

---

# 5. Module Design

## 5.1 User Interface Layer

### Responsibilities

* Display configuration controls
* Display simulator controls
* Display current speed and cadence
* Display error messages

Screen mockups in `./designs/` are visual references only (currently iPhone layout). iPadOS layouts are required but not yet mocked.

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
RootViewModel
ConfigurationViewModel
RunningViewModel
AppStateStore
```

The view models act as the boundary between UI and application logic.

### App Navigation State

Screen navigation (configuration vs running) is explicit via `AppState`:

```swift
enum AppState {
    case configuring
    case running
}
```

`AppStateStore` is an `@Observable` shared object created once in `AppContainer` and injected into `RootViewModel`, `ConfigurationViewModel`, and `RunningViewModel`. Child view models mutate it on successful start/stop; `RootViewModel` exposes `appState` for `RootView` to switch screens. This replaces inferring navigation from `SimulationEngine.isRunning` at the view-model layer.

* `ConfigurationViewModel.startEmulator()` calls `appStateStore.enterRunning()` after simulation and broadcaster start successfully.
* `RunningViewModel.stopEmulator()` calls `appStateStore.enterConfiguring()` after stopping the broadcaster and simulation (including the fatal BLE error auto-stop path).

`SimulationEngine.isRunning` remains the engine's internal tick-loop lifecycle flag and is not used for root navigation.

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
ManualState
RandomState
RandomCadenceGenerator
```

---

# 6. Simulator State Model

## Units

Speed and cadence are represented using Foundation `Measurement` rather than raw `Double` values.

Type aliases (defined in `Models/Units.swift`):

```swift
typealias Speed = Measurement<UnitSpeed>
typealias Cadence = Measurement<UnitFrequency>
```

Custom RPM unit on `UnitFrequency` (RPM = 1/60 Hz):

```swift
extension UnitFrequency {
    static let revolutionsPerMinute = UnitFrequency(
        symbol: "rpm",
        converter: UnitConverterLinear(coefficient: 1.0 / 60.0)
    )
}
```

`UnitSpeed.milesPerHour` is used for speed; no custom speed unit is required.

Display formatting uses `MeasurementFormatter` (or `.formatted()`) in views and view models.

---

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
    case random
    case manual
}
```

Random mode is the default when the emulator starts.

---

## SimulatorVitals

Shared measurement and capability data carried by every operating-mode state:

```swift
struct SimulatorVitals {
    var speed: Speed
    var cadence: Cadence
    var supportsSpeed: Bool
    var supportsCadence: Bool
}
```

## SimulatorState

Mode-specific behavior is encapsulated behind a protocol. Each concrete state type owns a `SimulatorVitals` value and implements tick and input rules for its operating mode:

```swift
protocol SimulatorState {
    var mode: OperatingMode { get }
    var vitals: SimulatorVitals { get }
    func tick() -> any SimulatorState
    func setSpeed(_ speed: Speed) -> any SimulatorState
    func setCadence(_ cadence: Cadence) -> any SimulatorState
}
```

Concrete implementations:

```text
RandomState     — random-walk cadence with derived speed; input ignored; default on start
ManualState     — user-controlled speed/cadence; tick is a no-op
```

The Simulation Engine owns the active `any SimulatorState` and the running lifecycle (`isRunning`).

---

# 7. Simulation Engine

## Responsibilities

* Maintain the active operating-mode state
* Execute simulation updates by delegating to the current `SimulatorState`
* Publish state changes
* Construct mode-specific states on mode transitions

## Update Frequency

The simulation engine shall execute at a fixed interval.

Initial target:

```text
1 Hz
```

This interval may be adjusted in future versions.

---

# 8. Random Mode

## Overview

Random mode simulates a rider pedaling continuously with natural cadence variations.

The user cannot directly manipulate speed or cadence.

Random mode is the default when the emulator starts.

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

The cadence generator shall implement a bounded random walk, updating every simulation tick (1 Hz).

Example update:

```text
cadence =
    cadence
    + randomDelta
    + biasToward90
```

Where:

```text
randomDelta ∈ [-1.5,+1.5] rpm
biasToward90 = (90 - cadenceInRPM) * 0.005
```

The exact constants may be tuned. Cadence values are stored as `Cadence` measurements using `.revolutionsPerMinute`.

---

## Speed Generation

Speed is derived from cadence proportionally across the operating ranges:

```text
speedMPH = cadenceInRPM * speedMaxMPH / cadenceMaxRPM
speed = Speed(value: speedMPH, unit: .milesPerHour)
```

---

# 9. Manual Mode

## Behavior

* User controls speed slider
* User controls cadence slider
* Values remain fixed until changed

No automatic updates occur.

---

# 10. BLE Subsystem

## Responsibilities

* Advertise the CSCS service
* Accept central connections
* Publish measurements
* Track subscriptions

---

## Device Name

No local name is advertised (PDR 0001).

---

## Service Configuration

The application shall expose:

```text
Cycling Speed and Cadence Service
```

The implementation shall follow the Bluetooth SIG CSCS specification.

---

## Measurement Characteristic

`RevolutionCounters` turns vitals into cumulative wheel and crank counts; `CSCServer` encodes the packet.

---

## Flag Selection

The CSC Feature bits follow the configuration. Each measurement's flags follow the halves that advanced on that tick: wheel only `0x01`, crank only `0x02`, both `0x03` (PDR 0004).

When speed is enabled, the SC Control Point characteristic is present; Set Cumulative Value responds with Operation Failed until phase 2 (PDR 0003).

---

# 11. Connection Management

## Supported Connections

All subscribing centrals.

---

## Connection Policy

Accept every connection; notify every subscriber (PDR 0002).

---

## UI Display

Connection status display is a future enhancement. The running screen is not required to show connection state in the initial release.

---

## Background Operation (iOS / iPadOS)

The app declares the `bluetooth-peripheral` background mode on iPhone and iPad so advertising and measurement notifications can continue while the app is backgrounded.

The emulator sets no local name. In the background, iOS may move the service UUID to the overflow area; centrals that scan for the CSCS service UUID can still discover and connect to the emulator.

State restoration (`CBPeripheralManagerOptionRestoreIdentifierKey`) is not implemented in the initial release.

---

# 12. Localization

The app UI, home-screen name, and Bluetooth permission prompt are localized using Xcode String Catalogs (`Localizable.xcstrings`, `InfoPlist.xcstrings`).

Supported languages: English (development language), Spanish, Simplified Chinese, Traditional Chinese, Japanese, German, French, Portuguese (Brazil), Korean, and Italian.

The Bluetooth SIG acronym **CSCS** is never translated. App Store listing metadata for each locale is stored under `documentation/app-store/`. Screenshots remain English-only for all storefronts (App Store Connect falls back to the primary-language set).

---

# 13. Revolution Counters

## Responsibilities

Convert simulator vitals into cumulative wheel and crank revolution samples for `CSCServer`. The counter logic has no CoreBluetooth dependencies and is unit tested independently.

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
│   ├── CSCSEmulatorApp.swift
│   └── AppContainer.swift
│
├── Models/
│   ├── Units.swift
│   ├── SimulatorConfiguration.swift
│   ├── SimulatorState.swift
│   ├── OperatingMode.swift
│   ├── AppState.swift
│   └── AppError.swift
│
├── Views/
│   ├── RootView.swift
│   ├── ConfigurationView.swift
│   └── RunningView.swift
│
├── ViewModels/
│   ├── RootViewModel.swift
│   ├── ConfigurationViewModel.swift
│   ├── RunningViewModel.swift
│   └── AppStateStore.swift
│
├── Simulation/
│   ├── SimulationEngine.swift
│   ├── ManualState.swift
│   ├── RandomState.swift
│   └── RandomCadenceGenerator.swift
│
├── BLE/
│   ├── MeasurementBroadcaster.swift
│   ├── MeasurementBroadcasting.swift
│   ├── MeasurementServer.swift
│   ├── RevolutionCounters.swift
│   ├── RevolutionAccumulator.swift
│   ├── CoreBluetoothStateMonitor.swift
│   ├── BluetoothStateMonitoring.swift
│   ├── BluetoothAvailabilityMapper.swift
│   └── BluetoothStateMapper.swift
│
├── Adaptors/
│   └── CSCServer/
│       └── Server+MeasurementServer.swift
│
└── Resources/
```

---

# 16. Future Enhancements

The architecture should support future additions including:

* Multiple virtual sensors
* Sensor battery simulation
* GPX route playback
* Ride recording and playback
* ANT+ support
* Additional BLE services
* Remote control APIs

without requiring significant restructuring of existing modules.
