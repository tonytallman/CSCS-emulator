//
//  RunningViewModel.swift
//  CSCSEmulator
//

import Foundation
import Observation

@Observable
@MainActor
final class RunningViewModel {
    private let simulation: SimulationControlling
    private let broadcaster: MeasurementBroadcasting
    let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>?

    private static let speedFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let cadenceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    init(
        simulation: SimulationControlling,
        broadcaster: MeasurementBroadcasting,
        simulationEngine: SimulationEngine<SystemRandomNumberGenerator>? = nil,
    ) {
        self.simulation = simulation
        self.broadcaster = broadcaster
        self.simulationEngine = simulationEngine
    }

    var isRunning: Bool {
        simulation.isRunning
    }

    var mode: OperatingMode {
        simulation.state.mode
    }

    var supportsSpeed: Bool {
        simulation.state.supportsSpeed
    }

    var supportsCadence: Bool {
        simulation.state.supportsCadence
    }

    var isConnected: Bool {
        broadcaster.isConnected
    }

    var lastError: AppError? {
        broadcaster.lastError
    }

    var slidersEnabled: Bool {
        mode == .pedaling
    }

    var formattedSpeed: String {
        Self.speedFormatter.string(from: simulation.state.speed)
    }

    var formattedCadence: String {
        Self.cadenceFormatter.string(from: simulation.state.cadence)
    }

    var speedRangeMPH: ClosedRange<Double> {
        let min = SimulatorRanges.speedMin.converted(to: .milesPerHour).value
        let max = SimulatorRanges.speedMax.converted(to: .milesPerHour).value
        return min...max
    }

    var cadenceRangeRPM: ClosedRange<Double> {
        let min = SimulatorRanges.cadenceMin.converted(to: .revolutionsPerMinute).value
        let max = SimulatorRanges.cadenceMax.converted(to: .revolutionsPerMinute).value
        return min...max
    }

    var speedMPH: Double {
        get {
            simulation.state.speed.converted(to: .milesPerHour).value
        }
        set {
            simulation.setSpeed(SimulatorRanges.clampedSpeed(.milesPerHour(newValue)))
        }
    }

    var cadenceRPM: Double {
        get {
            simulation.state.cadence.converted(to: .revolutionsPerMinute).value
        }
        set {
            simulation.setCadence(SimulatorRanges.clampedCadence(.rpm(newValue)))
        }
    }

    func setMode(_ mode: OperatingMode) {
        simulation.setMode(mode)
    }

    func stopEmulator() {
        broadcaster.stop()
        simulation.stop()
    }

    func handleErrorChange() {
        guard let error = lastError else { return }
        switch error {
        case .bluetoothUnavailable, .bluetoothDisabled:
            stopEmulator()
        case .advertisingFailed, .connectionFailed, .internalError:
            break
        }
    }

}
