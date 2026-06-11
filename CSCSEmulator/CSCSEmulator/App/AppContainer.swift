//
//  AppContainer.swift
//  CSCSEmulator
//

/// Composition root: constructs and wires application dependencies.
@MainActor
final class AppContainer {
    private let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>
    private let peripheralManager: CSCPeripheralManager

    init() {
        let engine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        simulationEngine = engine
        peripheralManager = CSCPeripheralManager { engine.state.vitals }
    }

    private func makeConfigurationViewModel() -> ConfigurationViewModel {
        ConfigurationViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
        )
    }

    private func makeRunningViewModel() -> RunningViewModel {
        RunningViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
            simulationEngine: simulationEngine,
        )
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(
            configurationViewModel: makeConfigurationViewModel(),
            runningViewModel: makeRunningViewModel(),
            simulationEngine: simulationEngine,
        )
    }
}
