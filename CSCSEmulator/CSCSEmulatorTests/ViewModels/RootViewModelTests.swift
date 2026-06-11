//
//  RootViewModelTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct RootViewModelTests {
    private func makeViewModel() -> (
        RootViewModel,
        SimulationEngine<SystemRandomNumberGenerator>,
        MeasurementBroadcastingSpy,
    ) {
        let appStateStore = AppStateStore()
        let engine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        let broadcaster = MeasurementBroadcastingSpy()
        let configurationViewModel = ConfigurationViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            appStateStore: appStateStore,
        )
        let runningViewModel = RunningViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            simulationEngine: engine,
            appStateStore: appStateStore,
        )
        let rootViewModel = RootViewModel(
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
        let (viewModel, _, _) = makeViewModel()
        viewModel.configurationViewModel.supportsSpeed = true
        viewModel.configurationViewModel.supportsCadence = true

        viewModel.configurationViewModel.startEmulator()

        #expect(viewModel.appState == .running)
    }

    @Test func appStateBecomesConfiguringAfterStopEmulator() {
        let (viewModel, _, _) = makeViewModel()
        viewModel.configurationViewModel.supportsSpeed = true
        viewModel.configurationViewModel.supportsCadence = true
        viewModel.configurationViewModel.startEmulator()

        viewModel.runningViewModel.stopEmulator()

        #expect(viewModel.appState == .configuring)
    }
}
