//
//  BluetoothAvailability.swift
//  CSCSEmulator
//

import Foundation

/// Whether BLE is ready to start advertising from the Configuration screen.
enum BluetoothAvailability: Equatable {
    case ready
    case permissionDenied
    case poweredOff
    case unavailable

    var appError: AppError? {
        switch self {
        case .ready:
            nil
        case .permissionDenied:
            .bluetoothPermissionDenied
        case .poweredOff:
            .bluetoothDisabled
        case .unavailable:
            .bluetoothUnavailable
        }
    }

    var showsSettingsButton: Bool {
        switch self {
        case .permissionDenied, .poweredOff:
            true
        case .ready, .unavailable:
            false
        }
    }
}
