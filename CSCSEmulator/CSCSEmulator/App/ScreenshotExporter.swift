//
//  ScreenshotExporter.swift
//  CSCSEmulator
//

import Foundation
import SwiftUI

#if DEBUG
#if os(macOS)
import AppKit
#endif

enum ScreenshotExporter {
    private static let exportMarker = "CSCS_SCREENSHOT_EXPORT="
    private static let exportFilename = "cscs-screenshot-export.png"
    private static let exportWidth: CGFloat = 480
    private static let exportHeight: CGFloat = 760

    static var shouldExport: Bool {
        ScreenshotLaunchMode.appState != nil && !ScreenshotLaunchMode.suppressScreenshotExport
    }

    @MainActor
    static func exportIfNeeded() {
        guard shouldExport else { return }

        #if os(macOS)
        exportMacView()
        #endif
    }

    @MainActor
    @ViewBuilder
    private static func screenshotRootView() -> some View {
        switch ScreenshotLaunchMode.appState {
        case .running:
            NavigationStack {
                RunningView(viewModel: PreviewRunningViewModel())
            }
        case .configuring, .none:
            NavigationStack {
                ConfigurationView(viewModel: PreviewConfigurationViewModel())
            }
        }
    }

    #if os(macOS)
    @MainActor
    private static func exportMacView() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))

            let content = screenshotRootView()
                .frame(width: exportWidth, height: exportHeight)

            let hostingView = NSHostingView(rootView: content)
            hostingView.frame = NSRect(x: 0, y: 0, width: exportWidth, height: exportHeight)
            hostingView.layoutSubtreeIfNeeded()

            guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)
            else {
                fputs("Screenshot export failed: could not create bitmap representation\n", stderr)
                NSApp.terminate(nil)
                return
            }

            hostingView.cacheDisplay(in: hostingView.bounds, to: representation)

            guard let data = representation.representation(using: .png, properties: [:]) else {
                fputs("Screenshot export failed: could not encode PNG\n", stderr)
                NSApp.terminate(nil)
                return
            }

            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(exportFilename)

            do {
                try data.write(to: destination, options: .atomic)
                print("\(exportMarker)\(destination.path)")
                fflush(stdout)
            } catch {
                fputs("Screenshot export failed: \(error)\n", stderr)
            }

            NSApp.terminate(nil)
        }
    }
    #endif
}
#endif
