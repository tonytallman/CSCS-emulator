//
//  ScreenshotLaunchMode.swift
//  CSCSEmulator
//

import Foundation

#if DEBUG
enum ScreenshotLaunchMode {
    private static let environmentKey = "CSCS_SCREENSHOT_MODE"

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
