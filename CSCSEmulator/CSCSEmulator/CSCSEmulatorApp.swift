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
                #if DEBUG
                .onAppear {
                    ScreenshotExporter.exportIfNeeded()
                }
                #endif
        }
        .defaultSize(width: 480, height: 760)
    }
}
