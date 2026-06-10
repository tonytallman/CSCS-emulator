//
//  AppError.swift
//  CSCSEmulator
//

import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case bluetoothUnavailable
    case bluetoothDisabled
    case advertisingFailed
    case connectionFailed
    case internalError

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            "Bluetooth is not available on this device."
        case .bluetoothDisabled:
            "Bluetooth is turned off. Enable Bluetooth in Settings to use the emulator."
        case .advertisingFailed:
            "Failed to start BLE advertising. Please try again."
        case .connectionFailed:
            "A BLE connection could not be established."
        case .internalError:
            "An unexpected error occurred. Please try again."
        }
    }
}
