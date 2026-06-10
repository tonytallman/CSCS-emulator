//
//  SimulatorConfiguration.swift
//  CSCSEmulator
//

struct SimulatorConfiguration: Equatable, Sendable {
    let supportsSpeed: Bool
    let supportsCadence: Bool

    /// At least one metric must be enabled (SRS section 3.1).
    var isValid: Bool {
        supportsSpeed || supportsCadence
    }
}
