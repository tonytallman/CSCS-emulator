//
//  ConfigurationViewModelTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

private struct StubSimulatorState: SimulatorState {
    let mode: OperatingMode
    let vitals: SimulatorVitals

    func setSpeed(_ speed: Speed) -> any SimulatorState {
        var updated = vitals
        updated.speed = SimulatorRanges.clampedSpeed(speed)
        return StubSimulatorState(mode: mode, vitals: updated)
    }

    func setCadence(_ cadence: Cadence) -> any SimulatorState {
        var updated = vitals
        updated.cadence = SimulatorRanges.clampedCadence(cadence)
        return StubSimulatorState(mode: mode, vitals: updated)
    }
}

@MainActor
final class SimulationControllingSpy: SimulationControlling {
    var onStart: (() -> Void)?
    private var internalState: any SimulatorState = PedalingState(
        vitals: .initial(supportsSpeed: true, supportsCadence: true)
    )

    var state: any SimulatorState { internalState }
    var isRunning = false

    private(set) var startCalls: [SimulatorConfiguration] = []
    private(set) var stopCallCount = 0
    private(set) var setModeCalls: [OperatingMode] = []
    private(set) var setSpeedCalls: [Speed] = []
    private(set) var setCadenceCalls: [Cadence] = []

    func start(configuration: SimulatorConfiguration) {
        onStart?()
        startCalls.append(configuration)
        isRunning = true
        internalState = PedalingState(
            vitals: .initial(
                supportsSpeed: configuration.supportsSpeed,
                supportsCadence: configuration.supportsCadence
            )
        )
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
    }

    func setMode(_ mode: OperatingMode) {
        setModeCalls.append(mode)
        let vitals = internalState.vitals
        switch mode {
        case .pedaling:
            internalState = PedalingState(vitals: vitals)
        case .coasting:
            internalState = CoastingState(vitals: vitals, coastingModel: CoastingModel())
        case .random:
            internalState = StubSimulatorState(mode: .random, vitals: vitals)
        }
    }

    func setSpeed(_ speed: Speed) {
        setSpeedCalls.append(speed)
        internalState = internalState.setSpeed(speed)
    }

    func setCadence(_ cadence: Cadence) {
        setCadenceCalls.append(cadence)
        internalState = internalState.setCadence(cadence)
    }
}

@MainActor
final class MeasurementBroadcastingSpy: MeasurementBroadcasting {
    var onStart: (() -> Void)?
    var isAdvertising = false
    var isConnected = false
    var lastError: AppError?
    var availability: BluetoothAvailability = .ready

    private(set) var startCalls: [SimulatorConfiguration] = []
    private(set) var stopCallCount = 0
    private(set) var prepareCallCount = 0
    private(set) var refreshAvailabilityCallCount = 0

    func prepare() {
        prepareCallCount += 1
    }

    func refreshAvailability() {
        refreshAvailabilityCallCount += 1
    }

    func start(configuration: SimulatorConfiguration) {
        onStart?()
        startCalls.append(configuration)
    }

    func stop() {
        stopCallCount += 1
        isAdvertising = false
        isConnected = false
    }
}

@MainActor
final class SettingsOpeningSpy: SettingsOpening {
    private(set) var openCallCount = 0

    func openBluetoothSettings() {
        openCallCount += 1
    }
}

@Suite @MainActor struct ConfigurationViewModelTests {
    private func makeViewModel(
        simulation: SimulationControllingSpy? = nil,
        broadcaster: MeasurementBroadcastingSpy? = nil,
        appStateStore: AppStateStore? = nil,
        settingsOpener: SettingsOpeningSpy? = nil,
    ) -> (
        AppConfigurationViewModel,
        SimulationControllingSpy,
        MeasurementBroadcastingSpy,
        AppStateStore,
        SettingsOpeningSpy,
    ) {
        let simulation = simulation ?? SimulationControllingSpy()
        let broadcaster = broadcaster ?? MeasurementBroadcastingSpy()
        let appStateStore = appStateStore ?? AppStateStore()
        let settingsOpener = settingsOpener ?? SettingsOpeningSpy()
        let viewModel = AppConfigurationViewModel(
            simulation: simulation,
            broadcaster: broadcaster,
            appStateStore: appStateStore,
            settingsOpener: settingsOpener,
        )
        return (viewModel, simulation, broadcaster, appStateStore, settingsOpener)
    }

    @Test(arguments: [
        (true, true),
        (true, false),
        (false, true),
    ])
    func canStartIsTrueForValidMetricCombinationsWhenBluetoothReady(
        supportsSpeed: Bool,
        supportsCadence: Bool,
    ) {
        let (viewModel, _, _, _, _) = makeViewModel()
        viewModel.supportsSpeed = supportsSpeed
        viewModel.supportsCadence = supportsCadence

        #expect(viewModel.canStart)
    }

    @Test func canStartIsFalseWhenBothMetricsDisabled() {
        let (viewModel, _, _, _, _) = makeViewModel()
        viewModel.supportsSpeed = false
        viewModel.supportsCadence = false

        #expect(!viewModel.canStart)
    }

    @Test(arguments: [
        BluetoothAvailability.permissionDenied,
        .poweredOff,
        .unavailable,
    ])
    func canStartIsFalseWhenBluetoothNotReady(availability: BluetoothAvailability) {
        let broadcaster = MeasurementBroadcastingSpy()
        broadcaster.availability = availability
        let (viewModel, _, _, _, _) = makeViewModel(broadcaster: broadcaster)
        viewModel.supportsSpeed = true
        viewModel.supportsCadence = true

        #expect(!viewModel.canStart)
    }

    @Test func startEmulatorStartsBroadcasterThenSimulationAfterAdvertising() {
        var startOrder: [String] = []
        let simulation = SimulationControllingSpy()
        simulation.onStart = { startOrder.append("simulation") }
        let broadcaster = MeasurementBroadcastingSpy()
        broadcaster.onStart = { startOrder.append("broadcaster") }
        let appStateStore = AppStateStore()
        let (viewModel, _, _, _, _) = makeViewModel(
            simulation: simulation,
            broadcaster: broadcaster,
            appStateStore: appStateStore,
        )
        viewModel.supportsSpeed = true
        viewModel.supportsCadence = false

        viewModel.startEmulator()

        let expected = SimulatorConfiguration(supportsSpeed: true, supportsCadence: false)
        #expect(viewModel.isStarting)
        #expect(broadcaster.startCalls == [expected])
        #expect(simulation.startCalls.isEmpty)
        #expect(appStateStore.state == .configuring)
        #expect(startOrder == ["broadcaster"])

        broadcaster.isAdvertising = true
        viewModel.handleStartOutcome()

        #expect(simulation.startCalls == [expected])
        #expect(startOrder == ["broadcaster", "simulation"])
        #expect(appStateStore.state == .running)
        #expect(!viewModel.isStarting)
    }

    @Test func handleStartOutcomeStaysOnConfigurationWhenStartFails() {
        let broadcaster = MeasurementBroadcastingSpy()
        broadcaster.lastError = .bluetoothPermissionDenied
        let (viewModel, simulation, _, appStateStore, _) = makeViewModel(broadcaster: broadcaster)
        viewModel.supportsSpeed = true
        viewModel.supportsCadence = true

        viewModel.startEmulator()
        viewModel.handleStartOutcome()

        #expect(simulation.startCalls.isEmpty)
        #expect(appStateStore.state == .configuring)
        #expect(!viewModel.isStarting)
    }

    @Test func handleStartOutcomeStaysOnConfigurationWhenAdvertisingFails() {
        let broadcaster = MeasurementBroadcastingSpy()
        let (viewModel, simulation, _, appStateStore, _) = makeViewModel(broadcaster: broadcaster)
        viewModel.supportsSpeed = true
        viewModel.supportsCadence = true

        viewModel.startEmulator()
        broadcaster.lastError = .advertisingFailed
        viewModel.handleStartOutcome()

        #expect(simulation.startCalls.isEmpty)
        #expect(appStateStore.state == .configuring)
        #expect(!viewModel.isStarting)
        #expect(!broadcaster.isAdvertising)
    }

    @Test func startEmulatorDoesNothingWhenCannotStart() {
        let simulation = SimulationControllingSpy()
        let broadcaster = MeasurementBroadcastingSpy()
        let appStateStore = AppStateStore()
        let (viewModel, _, _, _, _) = makeViewModel(
            simulation: simulation,
            broadcaster: broadcaster,
            appStateStore: appStateStore,
        )
        viewModel.supportsSpeed = false
        viewModel.supportsCadence = false

        viewModel.startEmulator()

        #expect(simulation.startCalls.isEmpty)
        #expect(broadcaster.startCalls.isEmpty)
        #expect(appStateStore.state == .configuring)
        #expect(!viewModel.isStarting)
    }

    @Test func openSettingsDelegatesToSettingsOpener() {
        let settingsOpener = SettingsOpeningSpy()
        let (viewModel, _, _, _, _) = makeViewModel(settingsOpener: settingsOpener)

        viewModel.openSettings()

        #expect(settingsOpener.openCallCount == 1)
    }

    @Test func refreshAvailabilityDelegatesToBroadcaster() {
        let broadcaster = MeasurementBroadcastingSpy()
        let (viewModel, _, _, _, _) = makeViewModel(broadcaster: broadcaster)

        viewModel.refreshAvailability()

        #expect(broadcaster.refreshAvailabilityCallCount == 1)
    }
}
