//
//  AppContainer.swift
//  CSCSEmulator
//

/// Composition root: constructs and wires application dependencies.
@MainActor
final class AppContainer {
    private let appStateStore = AppStateStore()
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
            appStateStore: appStateStore,
        )
    }

    private func makeRunningViewModel() -> RunningViewModel {
        RunningViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
            simulationEngine: simulationEngine,
            appStateStore: appStateStore,
        )
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(
            configurationViewModel: makeConfigurationViewModel(),
            runningViewModel: makeRunningViewModel(),
            appStateStore: appStateStore,
        )
    }
}
