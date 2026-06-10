//
//  AppContainer.swift
//  CSCSEmulator
//

/// Composition root: constructs and wires application dependencies.
/// Factory methods for view models and long-lived collaborators arrive in later phases.
@MainActor
final class AppContainer {
    let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>

    init(simulationEngine: SimulationEngine<SystemRandomNumberGenerator>) {
        self.simulationEngine = simulationEngine
    }

    init() {
        simulationEngine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
    }

    // Phase 4+: CSCPeripheralManager (shared)
    // Phase 5+: makeConfigurationViewModel() -> ConfigurationViewModel
    // Phase 5+: makeRunningViewModel() -> RunningViewModel
}
