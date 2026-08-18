//
//  AppError.swift
//  CSCSEmulator
//

import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case bluetoothUnavailable
    case bluetoothDisabled
    case bluetoothPermissionDenied
    case advertisingFailed
    case connectionFailed
    case internalError

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            String(localized: "Bluetooth is not available on this device.")
        case .bluetoothDisabled:
            String(localized: "Bluetooth is turned off. Enable Bluetooth in Settings to use the emulator.")
        case .bluetoothPermissionDenied:
            String(
                format: String(
                    localized: "Bluetooth permission is turned off. Enable Bluetooth access for %@ in Settings to start the emulator."
                ),
                AppInfo.displayName,
            )
        case .advertisingFailed:
            String(localized: "Failed to start BLE advertising. Please try again.")
        case .connectionFailed:
            String(localized: "A BLE connection could not be established.")
        case .internalError:
            String(localized: "An unexpected error occurred. Please try again.")
        }
    }
}
