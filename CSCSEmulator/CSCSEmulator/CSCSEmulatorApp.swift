//
//  CSCSEmulatorApp.swift
//  CSCSEmulator
//
//  Created by Tony Tallman on 6/10/26.
//

import SwiftUI

@main
struct CSCSEmulatorApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: container.makeRootViewModel())
        }
        .defaultSize(width: 480, height: 760)
    }
}
