# CSCS BLE Emulator Requirements

## 1. Overview

The CSCS BLE Emulator is a cross-platform application that advertises and publishes simulated Bluetooth Low Energy (BLE) Cycling Speed and Cadence Service (CSCS) data.

The primary purpose of the application is to allow developers, testers, and users to simulate a cycling speed and cadence sensor without requiring dedicated hardware.

The application shall support:

* iOS
* iPadOS
* macOS

A single codebase using SwiftUI is preferred.

---

## 2. Definitions

### CSCS

Cycling Speed and Cadence Service (Bluetooth LE standard service).

### Speed

Simulated bicycle speed.

### Cadence

Simulated pedaling cadence measured in revolutions per minute (RPM).

### Publishing

Advertising and transmitting CSCS measurement data via BLE.

---

## 3. User Interface

### 3.1 Configuration Screen

Before the emulator starts, the user shall be able to configure which metrics are supported by the simulated device.
See ./designs/configuration.png (visual reference only; screen mockups currently cover iPhone layout).

#### Controls

| Control               | Description                           |
| --------------------- | ------------------------------------- |
| Speed Switch          | Enables speed support                 |
| Cadence Switch        | Enables cadence support               |
| Start Emulator Button | Starts BLE advertising and simulation |

#### Rules

* The user may enable:

  * Speed only
  * Cadence only
  * Both speed and cadence
* At least one metric must be enabled before the emulator can start.
* After the emulator has started, supported metrics cannot be changed without stopping the emulator.

---

### 3.2 Running Screen

After the emulator starts, the application shall transition to a running state.
See ./designs/running.png (visual reference only; screen mockups currently cover iPhone layout).

#### Controls

| Control                | Description                                             |
| ---------------------- | ------------------------------------------------------- |
| Mode Segmented Control | Selects Pedaling, Coasting, or Random mode              |
| Speed Slider           | Controls simulated speed                                |
| Cadence Slider         | Controls simulated cadence                              |
| Stop Emulator Button   | Stops BLE advertising and returns to configuration mode |

#### Slider Visibility

##### Speed Slider

The Speed Slider shall be visible only when Speed support was enabled during configuration.

##### Cadence Slider

The Cadence Slider shall be visible only when Cadence support was enabled during configuration.

#### Slider Ranges

| Slider  | Range (MPH or RPM) |
| ------- | ------------------ |
| Speed   | 0–50 MPH           |
| Cadence | 0–200 RPM          |

These ranges shall accommodate Random-mode derived speed (200 RPM corresponds to approximately 44 MPH).

---

## 4. BLE Behavior

### 4.1 Device Name

While advertising, the BLE device name shall be:

```text
CSCS emulator
```

### 4.2 Advertising

The application shall advertise the Cycling Speed and Cadence Service.

### 4.3 Published Data

The application shall publish only the metrics selected during configuration.

Examples:

| Configuration   | Published Metrics |
| --------------- | ----------------- |
| Speed only      | Speed             |
| Cadence only    | Cadence           |
| Speed + Cadence | Speed and Cadence |

### 4.4 Central Connections

The emulator shall support at most one connected BLE central device at a time.

- If no central is connected, connection requests shall be accepted.
- If a central is already connected, additional connection requests shall be rejected.
- Connection status display is a future enhancement; see section 8.
- The identity of the connected central is not required to be displayed.

---

## 5. Operating Modes

### 5.1 Pedaling Mode

Pedaling mode represents active cycling.

#### Behavior

* All visible sliders shall be enabled.
* User adjustments immediately affect transmitted values.
* Published values remain constant until changed by the user.

---

### 5.2 Coasting Mode

Coasting mode represents a rider no longer pedaling.

#### Behavior

* All visible sliders shall be disabled.
* Cadence shall immediately become zero RPM.
* Speed shall decay toward zero.

#### Speed Decay

The exact decay profile is implementation-defined.

Acceptable examples include:

* Linear decay
* Exponential decay
* Simple physics-inspired decay

Requirements:

* Speed shall monotonically decrease toward zero.
* Speed shall never increase while in Coasting mode.

---

### 5.3 Random Mode

Random mode represents a rider pedaling with naturally varying cadence.

#### Behavior

* All visible sliders shall be disabled.
* Cadence shall be automatically generated.
* Speed shall be automatically derived from cadence.

#### Cadence Generation

Cadence generation shall follow a random-walk model.

Requirements:

* Successive cadence values shall be relatively continuous.
* Random changes shall be small and additive.
* Large instantaneous jumps shall be avoided.
* The cadence generator shall exhibit a weak tendency toward 90 RPM.
* The cadence generator may move above or below 90 RPM for extended periods.
* Cadence values shall remain within valid operating limits.

An example implementation may use:

```text
newCadence =
    previousCadence
    + randomDelta
    + biasToward90
```

where:

* randomDelta is a small random value
* biasToward90 is a small corrective force toward 90 RPM

#### Speed Generation

Speed shall be derived from cadence using:

```text
speed = cadence × 20 MPH / 90 RPM
```

Equivalent form:

```text
speed = cadence × 0.222222...
```

Examples:

| Cadence (RPM) | Speed (MPH) |
| ------------- | ----------- |
| 45            | 10.0        |
| 90            | 20.0        |
| 135           | 30.0        |

---

## 6. State Management

### Stopped State

Characteristics:

* No BLE advertising.
* Configuration controls enabled.
* Running controls hidden.

### Running State

Characteristics:

* BLE advertising active.
* Configuration controls locked.
* Running controls visible.

Transitions:

```text
Stopped
    |
    | Start Emulator
    v
Running
    |
    | Stop Emulator
    v
Stopped
```

---

## 7. Error Handling

The application shall gracefully handle:

* BLE unavailable
* Bluetooth disabled
* Advertising failures
* Permission denials
* Unsupported platform features

The user shall receive a clear error message describing the failure.

---

## 8. Future Enhancements (Non-Requirements)

Potential future features include:

* Wheel circumference configuration
* Crank length configuration
* Sensor battery level simulation
* Save/load presets
* ANT+ support
* GPX route playback
* Recorded ride playback
* Automatic interval generation
* Multiple virtual sensors
* FTMS integration
* Background operation
* BLE connection status display
