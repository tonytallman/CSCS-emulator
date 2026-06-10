//
//  SimulatorState.swift
//  CSCSEmulator
//

struct SimulatorState: Equatable, Sendable {
    var mode: OperatingMode
    var speed: Speed
    var cadence: Cadence
    var supportsSpeed: Bool
    var supportsCadence: Bool
    var isRunning: Bool

    static func initial(supportsSpeed: Bool, supportsCadence: Bool) -> SimulatorState {
        SimulatorState(
            mode: .pedaling,
            speed: .milesPerHour(0),
            cadence: .rpm(0),
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence,
            isRunning: false
        )
    }
}
