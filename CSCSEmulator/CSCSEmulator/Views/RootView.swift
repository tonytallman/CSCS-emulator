//
//  RootView.swift
//  CSCSEmulator
//

import Observation
import SwiftUI

@MainActor
protocol RootViewModel: AnyObject, Observable {
    associatedtype Configuration: ConfigurationViewModel
    associatedtype Running: RunningViewModel
    
    var configurationViewModel: Configuration { get }
    var runningViewModel: Running { get }
    var appState: AppState { get }
}

struct RootView<ViewModel: RootViewModel>: View {
    let viewModel: ViewModel
    
    var body: some View {
        NavigationStack {
            switch viewModel.appState {
            case .running:
                RunningView(viewModel: viewModel.runningViewModel)
            case .configuring:
                ConfigurationView(viewModel: viewModel.configurationViewModel)
            }
        }
    }
}

#if DEBUG
#Preview("Configuring") {
    RootView(viewModel: PreviewRootViewModel(appState: .configuring))
}

#Preview("Running") {
    RootView(viewModel: PreviewRootViewModel(appState: .running))
}
#endif
