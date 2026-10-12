//
//  AppContainer.swift
//  CSCSEmulator
//

/// Composition root: constructs and wires application dependencies.
@MainActor
final class AppContainer {
    private let appStateStore: AppStateStore
    private let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>
    private let broadcaster: MeasurementBroadcaster

    init() {
        let appStateStore = AppStateStore()
        #if DEBUG
        if let screenshotState = ScreenshotLaunchMode.appState {
            switch screenshotState {
            case .running:
                appStateStore.enterRunning()
            case .configuring:
                break
            }
        }
        #endif
        self.appStateStore = appStateStore

        let engine = SimulationEngine(
            randomCadenceGenerator: RandomCadenceGenerator(rng: SystemRandomNumberGenerator()),
        )
        simulationEngine = engine
        broadcaster = MeasurementBroadcaster(
            bluetooth: CoreBluetoothStateMonitor(),
            makeServer: { ServerToMeasurementServer(configuration: $0) },
            vitalsProvider: { engine.state.vitals },
        )
        broadcaster.prepare()

        #if DEBUG
        if ScreenshotLaunchMode.appState == .running {
            simulationEngine.start(
                configuration: SimulatorConfiguration(
                    supportsSpeed: true,
                    supportsCadence: true,
                ),
            )
        }
        #endif
    }

    private func makeConfigurationViewModel() -> AppConfigurationViewModel {
        AppConfigurationViewModel(
            simulation: simulationEngine,
            broadcaster: broadcaster,
            appStateStore: appStateStore,
            settingsOpener: SystemSettingsOpener(),
        )
    }

    private func makeRunningViewModel() -> AppRunningViewModel {
        AppRunningViewModel(
            simulation: simulationEngine,
            broadcaster: broadcaster,
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
