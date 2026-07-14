//
//  MeasurementBroadcasting.swift
//  CSCSEmulator
//

import Foundation

/// Abstraction over BLE measurement publishing for view models and tests.
@MainActor
protocol MeasurementBroadcasting: AnyObject {
    var isAdvertising: Bool { get }
    var isConnected: Bool { get }
    var lastError: AppError? { get }
    var availability: BluetoothAvailability { get }

    func prepare()
    func refreshAvailability()
    func start(configuration: SimulatorConfiguration)
    func stop()
}

extension CSCPeripheralManager: MeasurementBroadcasting {}
