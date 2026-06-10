//
//  SimulationControlling.swift
//  CSCSEmulator
//

import Foundation

/// Abstraction over the simulation engine for view models and tests.
@MainActor
protocol SimulationControlling: AnyObject {
    var state: any SimulatorState { get }
    var isRunning: Bool { get }

    func start(configuration: SimulatorConfiguration)
    func stop()
    func setMode(_ mode: OperatingMode)
    func setSpeed(_ speed: Speed)
    func setCadence(_ cadence: Cadence)
}

extension SimulationEngine: SimulationControlling {}
