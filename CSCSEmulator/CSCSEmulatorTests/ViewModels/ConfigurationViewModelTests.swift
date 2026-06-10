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
            var updated = vitals
            updated.cadence = .rpm(0)
            internalState = CoastingState(vitals: updated, coastingModel: CoastingModel())
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

    private(set) var startCalls: [SimulatorConfiguration] = []
    private(set) var stopCallCount = 0

    func start(configuration: SimulatorConfiguration) {
        onStart?()
        startCalls.append(configuration)
        isAdvertising = true
    }

    func stop() {
        stopCallCount += 1
        isAdvertising = false
        isConnected = false
    }
}

@Suite @MainActor struct ConfigurationViewModelTests {
    private func makeViewModel(
        simulation: SimulationControllingSpy? = nil,
        broadcaster: MeasurementBroadcastingSpy? = nil
    ) -> (ConfigurationViewModel, SimulationControllingSpy, MeasurementBroadcastingSpy) {
        let simulation = simulation ?? SimulationControllingSpy()
        let broadcaster = broadcaster ?? MeasurementBroadcastingSpy()
        let viewModel = ConfigurationViewModel(simulation: simulation, broadcaster: broadcaster)
        return (viewModel, simulation, broadcaster)
    }

    @Test(arguments: [
        (true, true),
        (true, false),
        (false, true),
    ])
    func canStartIsTrueForValidMetricCombinations(supportsSpeed: Bool, supportsCadence: Bool) {
        let (viewModel, _, _) = makeViewModel()
        viewModel.supportsSpeed = supportsSpeed
        viewModel.supportsCadence = supportsCadence

        #expect(viewModel.canStart)
    }

    @Test func canStartIsFalseWhenBothMetricsDisabled() {
        let (viewModel, _, _) = makeViewModel()
        viewModel.supportsSpeed = false
        viewModel.supportsCadence = false

        #expect(!viewModel.canStart)
    }

    @Test func startEmulatorPassesConfigurationToSimulationThenBroadcaster() {
        var startOrder: [String] = []
        let simulation = SimulationControllingSpy()
        simulation.onStart = { startOrder.append("simulation") }
        let broadcaster = MeasurementBroadcastingSpy()
        broadcaster.onStart = { startOrder.append("broadcaster") }
        let viewModel = ConfigurationViewModel(simulation: simulation, broadcaster: broadcaster)
        viewModel.supportsSpeed = true
        viewModel.supportsCadence = false

        viewModel.startEmulator()

        let expected = SimulatorConfiguration(supportsSpeed: true, supportsCadence: false)
        #expect(simulation.startCalls == [expected])
        #expect(broadcaster.startCalls == [expected])
        #expect(startOrder == ["simulation", "broadcaster"])
    }

    @Test func startEmulatorDoesNothingWhenCannotStart() {
        let simulation = SimulationControllingSpy()
        let broadcaster = MeasurementBroadcastingSpy()
        let viewModel = ConfigurationViewModel(simulation: simulation, broadcaster: broadcaster)
        viewModel.supportsSpeed = false
        viewModel.supportsCadence = false

        viewModel.startEmulator()

        #expect(simulation.startCalls.isEmpty)
        #expect(broadcaster.startCalls.isEmpty)
    }
}
