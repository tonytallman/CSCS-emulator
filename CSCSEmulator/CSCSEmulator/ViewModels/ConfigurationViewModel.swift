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
    private(set) var isStarting = false

    private let simulation: SimulationControlling
    private let broadcaster: MeasurementBroadcasting
    private let appStateStore: AppStateStore
    private let settingsOpener: SettingsOpening
    private var pendingConfiguration: SimulatorConfiguration?

    init(
        simulation: SimulationControlling,
        broadcaster: MeasurementBroadcasting,
        appStateStore: AppStateStore,
        settingsOpener: SettingsOpening,
    ) {
        self.simulation = simulation
        self.broadcaster = broadcaster
        self.appStateStore = appStateStore
        self.settingsOpener = settingsOpener
    }

    var availability: BluetoothAvailability {
        broadcaster.availability
    }

    var isAdvertising: Bool {
        broadcaster.isAdvertising
    }

    var canStart: Bool {
        SimulatorConfiguration(
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence,
        ).isValid && availability == .ready
    }

    var lastError: AppError? {
        broadcaster.lastError
    }

    func startEmulator() {
        let configuration = SimulatorConfiguration(
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence,
        )
        guard configuration.isValid, availability == .ready else { return }

        pendingConfiguration = configuration
        isStarting = true
        broadcaster.start(configuration: configuration)
    }

    func handleStartOutcome() {
        guard isStarting else { return }

        if broadcaster.isAdvertising {
            guard let configuration = pendingConfiguration else { return }

            simulation.start(configuration: configuration)
            appStateStore.enterRunning()
            isStarting = false
            pendingConfiguration = nil
            return
        }

        if broadcaster.lastError != nil || broadcaster.availability != .ready {
            isStarting = false
            pendingConfiguration = nil
        }
    }

    func openSettings() {
        settingsOpener.openBluetoothSettings()
    }

    func refreshAvailability() {
        broadcaster.refreshAvailability()
    }
}
