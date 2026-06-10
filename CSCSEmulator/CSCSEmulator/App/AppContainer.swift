//
//  AppContainer.swift
//  CSCSEmulator
//

/// Composition root: constructs and wires application dependencies.
/// Factory methods for view models and long-lived collaborators arrive in later phases.
final class AppContainer {
    init() {}

    // Phase 2+: SimulationEngine (shared)
    // Phase 4+: CSCPeripheralManager (shared)
    // Phase 5+: makeConfigurationViewModel() -> ConfigurationViewModel
    // Phase 5+: makeRunningViewModel() -> RunningViewModel
}
