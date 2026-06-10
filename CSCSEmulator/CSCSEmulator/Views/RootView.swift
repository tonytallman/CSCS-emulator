//
//  RootView.swift
//  CSCSEmulator
//

import SwiftUI

struct RootView: View {
    @Bindable var configurationViewModel: ConfigurationViewModel
    @Bindable var runningViewModel: RunningViewModel

    var body: some View {
        NavigationStack {
            if let engine = runningViewModel.observableEngine as? SimulationEngine<SystemRandomNumberGenerator> {
                ObservedRootContent(
                    configurationViewModel: configurationViewModel,
                    runningViewModel: runningViewModel,
                    engine: engine
                )
            } else {
                if runningViewModel.isRunning {
                    RunningView(viewModel: runningViewModel)
                } else {
                    ConfigurationView(viewModel: configurationViewModel)
                }
            }
        }
    }
}

private struct ObservedRootContent: View {
    @Bindable var configurationViewModel: ConfigurationViewModel
    @Bindable var runningViewModel: RunningViewModel
    @Bindable var engine: SimulationEngine<SystemRandomNumberGenerator>

    var body: some View {
        if engine.isRunning {
            RunningView(viewModel: runningViewModel, engine: engine)
        } else {
            ConfigurationView(viewModel: configurationViewModel)
        }
    }
}
