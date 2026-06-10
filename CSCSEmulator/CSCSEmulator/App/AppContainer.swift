//
//  AppContainer.swift
//  CSCSEmulator
//

/// Composition root: constructs and wires application dependencies.
/// Factory methods for view models and long-lived collaborators arrive in later phases.
@MainActor
final class AppContainer {
    let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>
    let peripheralManager: CSCPeripheralManager

    init(
        simulationEngine: SimulationEngine<SystemRandomNumberGenerator>,
        peripheralManager: CSCPeripheralManager,
    ) {
        self.simulationEngine = simulationEngine
        self.peripheralManager = peripheralManager
    }

    init() {
        let engine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        simulationEngine = engine
        peripheralManager = CSCPeripheralManager { engine.state.vitals }
    }

    func makeConfigurationViewModel() -> ConfigurationViewModel {
        ConfigurationViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
        )
    }

    func makeRunningViewModel() -> RunningViewModel {
        RunningViewModel(
            simulation: simulationEngine,
            broadcaster: peripheralManager,
            observableEngine: simulationEngine,
        )
    }
}
