//
//  CoreBluetoothStateMonitor.swift
//  CSCSEmulator
//

import CoreBluetooth

@MainActor
final class CoreBluetoothStateMonitor: NSObject, BluetoothStateMonitoring {
    var authorization: CBManagerAuthorization { CBManager.authorization }
    var state: CBManagerState? { manager?.state }
    var onStateChange: ((CBManagerState) -> Void)?

    private var manager: CBPeripheralManager?

    func activate() {
        guard manager == nil else { return }
        manager = CBPeripheralManager(
            delegate: self,
            queue: .main,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: false],
        )
    }
}

extension CoreBluetoothStateMonitor: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let state = peripheral.state
        MainActor.assumeIsolated {
            onStateChange?(state)
        }
    }
}
