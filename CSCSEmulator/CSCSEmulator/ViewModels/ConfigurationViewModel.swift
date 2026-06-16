//
//  ConfigurationViewModel.swift
//  CSCSEmulator
//

import Foundation
import Observation

@Observable
@MainActor
final class AppConfigurationViewModel: ConfigurationViewModel {
    var supportsSpeed = true
    var supportsCadence = true

    private let simulation: SimulationControlling
    private let broadcaster: MeasurementBroadcasting
    private let appStateStore: AppStateStore

    init(
        simulation: SimulationControlling,
        broadcaster: MeasurementBroadcasting,
        appStateStore: AppStateStore,
    ) {
        self.simulation = simulation
        self.broadcaster = broadcaster
        self.appStateStore = appStateStore
    }

    var canStart: Bool {
        SimulatorConfiguration(
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence
        ).isValid
    }

    var lastError: AppError? {
        broadcaster.lastError
    }

    func startEmulator() {
        let configuration = SimulatorConfiguration(
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence
        )
        guard configuration.isValid else { return }

        simulation.start(configuration: configuration)
        broadcaster.start(configuration: configuration)
        appStateStore.enterRunning()
    }
}
