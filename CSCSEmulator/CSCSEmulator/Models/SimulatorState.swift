//
//  SimulatorState.swift
//  CSCSEmulator
//

/// Shared measurement and capability data carried by every operating-mode state.
struct SimulatorVitals: Equatable, Sendable {
    var speed: Speed
    var cadence: Cadence
    let supportsSpeed: Bool
    let supportsCadence: Bool

    static func initial(supportsSpeed: Bool, supportsCadence: Bool) -> SimulatorVitals {
        SimulatorVitals(
            speed: .stopped,
            cadence: .stopped,
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence,
        )
    }
}

/// Encapsulates mode-specific simulation behavior (SDD sections 8–10).
protocol SimulatorState {
    var mode: OperatingMode { get }
    var vitals: SimulatorVitals { get }
    func tick() -> any SimulatorState
    func setSpeed(_ speed: Speed) -> any SimulatorState
    func setCadence(_ cadence: Cadence) -> any SimulatorState
}

extension SimulatorState {
    var speed: Speed { vitals.speed }
    var cadence: Cadence { vitals.cadence }
    var supportsSpeed: Bool { vitals.supportsSpeed }
    var supportsCadence: Bool { vitals.supportsCadence }

    func tick() -> any SimulatorState { self }
    func setSpeed(_ speed: Speed) -> any SimulatorState { self }
    func setCadence(_ cadence: Cadence) -> any SimulatorState { self }
}
