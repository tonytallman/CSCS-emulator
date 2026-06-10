//
//  BluetoothStateMapper.swift
//  CSCSEmulator
//

import CoreBluetooth

/// Maps CoreBluetooth manager state to user-facing application errors.
enum BluetoothStateMapper {
    static func error(for state: CBManagerState) -> AppError? {
        switch state {
        case .unsupported, .unauthorized:
            .bluetoothUnavailable
        case .poweredOff:
            .bluetoothDisabled
        case .poweredOn, .unknown, .resetting:
            nil
        @unknown default:
            .bluetoothUnavailable
        }
    }
}
