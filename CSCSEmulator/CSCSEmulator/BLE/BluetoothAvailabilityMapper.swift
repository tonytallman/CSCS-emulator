//
//  BluetoothAvailabilityMapper.swift
//  CSCSEmulator
//

import CoreBluetooth

/// Maps CoreBluetooth authorization and manager state to Configuration-screen readiness.
enum BluetoothAvailabilityMapper {
    static func availability(
        authorization: CBManagerAuthorization,
        state: CBManagerState?,
    ) -> BluetoothAvailability {
        switch authorization {
        case .denied, .restricted:
            return .permissionDenied
        case .notDetermined:
            return .ready
        case .allowedAlways:
            guard let state else {
                return .ready
            }
            switch state {
            case .poweredOn, .unknown, .resetting:
                return .ready
            case .poweredOff:
                return .poweredOff
            case .unsupported, .unauthorized:
                return .unavailable
            @unknown default:
                return .unavailable
            }
        @unknown default:
            return .unavailable
        }
    }
}
