//
//  RootView.swift
//  CSCSEmulator
//

import SwiftUI

struct RootView: View {
    @Bindable var viewModel: RootViewModel

    var body: some View {
        NavigationStack {
            if viewModel.isRunning {
                RunningView(viewModel: viewModel.runningViewModel)
            } else {
                ConfigurationView(viewModel: viewModel.configurationViewModel)
            }
        }
    }
}
