//
//  BluetoothStateMonitoring.swift
//  CSCSEmulator
//

import CoreBluetooth

@MainActor
protocol BluetoothStateMonitoring: AnyObject {
    var authorization: CBManagerAuthorization { get }
    var state: CBManagerState? { get }
    var onStateChange: ((CBManagerState) -> Void)? { get set }
    func activate()
}
