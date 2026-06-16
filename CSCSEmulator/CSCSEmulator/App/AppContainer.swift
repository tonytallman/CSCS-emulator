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

    private func makeConfigurationViewModel() -> AppConfigurationViewModel {
        AppConfigurationViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
            appStateStore: appStateStore,
        )
    }

    private func makeRunningViewModel() -> AppRunningViewModel {
        AppRunningViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
            simulationEngine: simulationEngine,
            appStateStore: appStateStore,
        )
    }

    func makeRootViewModel() -> AppRootViewModel {
        AppRootViewModel(
            configurationViewModel: makeConfigurationViewModel(),
            runningViewModel: makeRunningViewModel(),
            appStateStore: appStateStore,
        )
    }
}
