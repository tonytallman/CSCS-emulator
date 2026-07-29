//
//  RootViewModelTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct RootViewModelTests {
    private func makeViewModel() -> (
        AppRootViewModel,
        SimulationEngine<SystemRandomNumberGenerator>,
        MeasurementBroadcastingSpy,
    ) {
        let appStateStore = AppStateStore()
        let engine = SimulationEngine(
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        let broadcaster = MeasurementBroadcastingSpy()
        let configurationViewModel = AppConfigurationViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            appStateStore: appStateStore,
            settingsOpener: SettingsOpeningSpy(),
        )
        let runningViewModel = AppRunningViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            simulationEngine: engine,
            appStateStore: appStateStore,
        )
        let rootViewModel = AppRootViewModel(
            configurationViewModel: configurationViewModel,
            runningViewModel: runningViewModel,
            appStateStore: appStateStore,
        )
        return (rootViewModel, engine, broadcaster)
    }

    @Test func appStateIsConfiguringInitially() {
        let (viewModel, _, _) = makeViewModel()

        #expect(viewModel.appState == .configuring)
    }

    @Test func appStateBecomesRunningAfterStartEmulator() {
        let (viewModel, _, broadcaster) = makeViewModel()
        viewModel.configurationViewModel.supportsSpeed = true
        viewModel.configurationViewModel.supportsCadence = true

        viewModel.configurationViewModel.startEmulator()
        broadcaster.isAdvertising = true
        viewModel.configurationViewModel.handleStartOutcome()

        #expect(viewModel.appState == .running)
    }

    @Test func appStateBecomesConfiguringAfterStopEmulator() {
        let (viewModel, _, broadcaster) = makeViewModel()
        viewModel.configurationViewModel.supportsSpeed = true
        viewModel.configurationViewModel.supportsCadence = true
        viewModel.configurationViewModel.startEmulator()
        broadcaster.isAdvertising = true
        viewModel.configurationViewModel.handleStartOutcome()

        viewModel.runningViewModel.stopEmulator()

        #expect(viewModel.appState == .configuring)
    }
}
