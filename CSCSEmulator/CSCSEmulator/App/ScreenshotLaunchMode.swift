//
//  ScreenshotLaunchMode.swift
//  CSCSEmulator
//

import Foundation

#if DEBUG
enum ScreenshotLaunchMode {
    private static let environmentKey = "CSCS_SCREENSHOT_MODE"
    private static let demoModeKey = "CSCS_DEMO_MODE"

    /// When set with `CSCS_SCREENSHOT_MODE`, keeps the app open for screen recording on macOS.
    static var suppressScreenshotExport: Bool {
        ProcessInfo.processInfo.environment[demoModeKey] == "1"
    }

    static var appState: AppState? {
        guard let value = ProcessInfo.processInfo.environment[environmentKey] else {
            return nil
        }

        switch value {
        case "configuration":
            return .configuring
        case "running":
            return .running
        default:
            return nil
        }
    }
}
#endif
