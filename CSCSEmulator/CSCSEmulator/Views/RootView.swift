//
//  RootView.swift
//  CSCSEmulator
//

import SwiftUI

struct RootView: View {
    @Bindable var viewModel: RootViewModel

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
