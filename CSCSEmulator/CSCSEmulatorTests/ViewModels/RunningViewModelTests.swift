//
//  RunningViewModelTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct RunningViewModelTests {
    private func makeEngine() -> SimulationEngine<SystemRandomNumberGenerator> {
        let engine = SimulationEngine(
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        return engine
    }

    private func makeViewModel(
        engine: SimulationEngine<SystemRandomNumberGenerator>? = nil,
        broadcaster: MeasurementBroadcastingSpy? = nil,
        appStateStore: AppStateStore? = nil,
    ) -> (
        AppRunningViewModel,
        SimulationEngine<SystemRandomNumberGenerator>,
        MeasurementBroadcastingSpy,
        AppStateStore,
    ) {
        let engine = engine ?? makeEngine()
        let broadcaster = broadcaster ?? MeasurementBroadcastingSpy()
        let appStateStore = appStateStore ?? AppStateStore()
        let viewModel = AppRunningViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            simulationEngine: engine,
            appStateStore: appStateStore,
        )
        return (viewModel, engine, broadcaster, appStateStore)
    }

    @Test(arguments: OperatingMode.allCases)
    func slidersEnabledOnlyInManual(mode: OperatingMode) {
        let (viewModel, engine, _, _) = makeViewModel()
        engine.setMode(mode)

        #expect(viewModel.slidersEnabled == (mode == .manual))
    }

    @Test func speedSetterForwardsClampedValueToEngine() {
        let (viewModel, engine, _, _) = makeViewModel()
        engine.setMode(.manual)

        viewModel.speedMPH = 100

        #expect(viewModel.speedMPH == 50)
    }

    @Test func cadenceSetterForwardsClampedValueToEngine() {
        let (viewModel, engine, _, _) = makeViewModel()
        engine.setMode(.manual)

        viewModel.cadenceRPM = 250

        #expect(viewModel.cadenceRPM == 200)
    }

    @Test func sliderGettersReflectVitals() {
        let (viewModel, engine, _, _) = makeViewModel()
        engine.setMode(.manual)
        engine.setSpeed(.milesPerHour(22.5))
        engine.setCadence(.rpm(95))

        #expect(viewModel.speedMPH == 22.5)
        #expect(viewModel.cadenceRPM == 95)
    }

    @Test func setModeForwardsToEngine() {
        let (viewModel, engine, _, _) = makeViewModel()

        viewModel.setMode(.manual)

        #expect(engine.state.mode == .manual)
    }

    @Test func stopEmulatorStopsBroadcasterAndEngine() {
        let (viewModel, engine, broadcaster, appStateStore) = makeViewModel()
        appStateStore.enterRunning()

        viewModel.stopEmulator()

        #expect(broadcaster.stopCallCount == 1)
        #expect(!engine.isRunning)
        #expect(appStateStore.state == .configuring)
    }

    @Test(arguments: [
        AppError.bluetoothUnavailable,
        AppError.bluetoothDisabled,
        AppError.bluetoothPermissionDenied,
    ])
    func bluetoothUnavailableErrorStopsBroadcasterAndEngine(error: AppError) {
        let engine = makeEngine()
        let broadcaster = MeasurementBroadcastingSpy()
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        let appStateStore = AppStateStore()
        appStateStore.enterRunning()
        let viewModel = AppRunningViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            simulationEngine: engine,
            appStateStore: appStateStore,
        )

        broadcaster.lastError = error
        viewModel.handleErrorChange()

        #expect(broadcaster.stopCallCount == 1)
        #expect(!engine.isRunning)
        #expect(appStateStore.state == .configuring)
    }

    @Test func nonFatalErrorDoesNotStopEmulator() {
        let engine = makeEngine()
        let broadcaster = MeasurementBroadcastingSpy()
        let appStateStore = AppStateStore()
        appStateStore.enterRunning()
        let viewModel = AppRunningViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            simulationEngine: engine,
            appStateStore: appStateStore,
        )

        broadcaster.lastError = .advertisingFailed
        viewModel.handleErrorChange()

        #expect(broadcaster.stopCallCount == 0)
        #expect(engine.isRunning)
        #expect(appStateStore.state == .running)
    }
}
