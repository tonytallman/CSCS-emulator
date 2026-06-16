//
//  RootViewModel.swift
//  CSCSEmulator
//

import Foundation
import Observation

@Observable
@MainActor
final class AppRootViewModel: RootViewModel {
    private let appConfigurationViewModel: AppConfigurationViewModel
    private let appRunningViewModel: AppRunningViewModel
    private let appStateStore: AppStateStore

    init(
        configurationViewModel: AppConfigurationViewModel,
        runningViewModel: AppRunningViewModel,
        appStateStore: AppStateStore,
    ) {
        self.appConfigurationViewModel = configurationViewModel
        self.appRunningViewModel = runningViewModel
        self.appStateStore = appStateStore
    }

    var configurationViewModel: some ConfigurationViewModel {
        appConfigurationViewModel
    }

    var runningViewModel: some RunningViewModel {
        appRunningViewModel
    }

    var appState: AppState {
        appStateStore.state
    }
}
