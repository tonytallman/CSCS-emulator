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
        let engine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        let broadcaster = MeasurementBroadcastingSpy()
        let configurationViewModel = ConfigurationViewModel(
            simulation: engine,
            broadcaster: broadcaster,
        )
        let runningViewModel = RunningViewModel(
            simulation: engine,
            broadcaster: broadcaster,
            simulationEngine: engine,
        )
        let rootViewModel = RootViewModel(
            configurationViewModel: configurationViewModel,
            runningViewModel: runningViewModel,
            simulationEngine: engine,
        )
        return (rootViewModel, engine, broadcaster)
    }

    @Test func isRunningIsFalseInitially() {
        let (viewModel, _, _) = makeViewModel()

        #expect(!viewModel.isRunning)
    }

    @Test func isRunningBecomesTrueAfterStartEmulator() {
        let (viewModel, _, _) = makeViewModel()
        viewModel.configurationViewModel.supportsSpeed = true
        viewModel.configurationViewModel.supportsCadence = true

        viewModel.configurationViewModel.startEmulator()

        #expect(viewModel.isRunning)
    }

    @Test func isRunningBecomesFalseAfterStopEmulator() {
        let (viewModel, _, _) = makeViewModel()
        viewModel.configurationViewModel.supportsSpeed = true
        viewModel.configurationViewModel.supportsCadence = true
        viewModel.configurationViewModel.startEmulator()

        viewModel.runningViewModel.stopEmulator()

        #expect(!viewModel.isRunning)
    }
}
