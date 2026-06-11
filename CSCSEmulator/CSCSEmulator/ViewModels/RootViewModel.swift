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
    private let appStateStore: AppStateStore

    init(
        configurationViewModel: ConfigurationViewModel,
        runningViewModel: RunningViewModel,
        appStateStore: AppStateStore,
    ) {
        self.configurationViewModel = configurationViewModel
        self.runningViewModel = runningViewModel
        self.appStateStore = appStateStore
    }

    var appState: AppState {
        appStateStore.state
    }
}
