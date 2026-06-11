//
//  RootViewModel.swift
//  CSCSEmulator
//

import Foundation
import Observation

@Observable
@MainActor
final class RootViewModel {
    let configurationViewModel: ConfigurationViewModel
    let runningViewModel: RunningViewModel
    let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>

    init(
        configurationViewModel: ConfigurationViewModel,
        runningViewModel: RunningViewModel,
        simulationEngine: SimulationEngine<SystemRandomNumberGenerator>,
    ) {
        self.configurationViewModel = configurationViewModel
        self.runningViewModel = runningViewModel
        self.simulationEngine = simulationEngine
    }

    var isRunning: Bool {
        simulationEngine.isRunning
    }
}
