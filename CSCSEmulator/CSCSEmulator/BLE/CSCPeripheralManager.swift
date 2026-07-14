//
//  CSCPeripheralManager.swift
//  CSCSEmulator
//

import CoreBluetooth
import Foundation
import Observation

private let measurementNotifyInterval: Duration = .seconds(1)

/// Advertises the CSCS peripheral and publishes measurement notifications (SDD sections 11–12).
@Observable
@MainActor
final class CSCPeripheralManager: NSObject {
    private(set) var isAdvertising = false
    private(set) var isConnected = false
    private(set) var lastError: AppError?
    private(set) var availability: BluetoothAvailability = .ready

    private let vitalsProvider: () -> SimulatorVitals

    private var peripheralManager: CBPeripheralManager?
    private var measurementEncoder = CSCSMeasurementEncoder()
    private var subscriptionTracker = CentralSubscriptionTracker()
    private var activeCentral: CBCentral?

    private var measurementCharacteristic: CBMutableCharacteristic?
    private var featureCharacteristic: CBMutableCharacteristic?
    private var featureValue = Data()

    private var pendingStartConfiguration: SimulatorConfiguration?
    private var notifyTask: Task<Void, Never>?
    private var notifyPaused = false

    init(vitalsProvider: @escaping () -> SimulatorVitals) {
        self.vitalsProvider = vitalsProvider
        super.init()
    }

    func prepare() {
        if CBManager.authorization != .notDetermined, peripheralManager == nil {
            peripheralManager = makePeripheralManager()
        }
        updateAvailability()
    }

    func refreshAvailability() {
        if CBManager.authorization != .notDetermined, peripheralManager == nil {
            peripheralManager = makePeripheralManager()
        }
        updateAvailability()
    }

    func start(configuration: SimulatorConfiguration) {
        guard configuration.isValid else { return }

        stop()
        lastError = nil
        pendingStartConfiguration = configuration
        measurementEncoder = CSCSMeasurementEncoder()
        subscriptionTracker.reset()
        featureValue = CSCSIdentifiers.featureValue(
            supportsSpeed: configuration.supportsSpeed,
            supportsCadence: configuration.supportsCadence
        )

        if peripheralManager == nil {
            peripheralManager = makePeripheralManager()
        }

        updateAvailability()

        if peripheralManager?.state == .poweredOn {
            setupServiceAndAdvertise()
        }
    }

    func stop() {
        notifyTask?.cancel()
        notifyTask = nil
        notifyPaused = false

        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()

        pendingStartConfiguration = nil
        measurementCharacteristic = nil
        featureCharacteristic = nil
        activeCentral = nil
        subscriptionTracker.reset()

        isAdvertising = false
        isConnected = false
        updateAvailability()
    }

    private func makePeripheralManager() -> CBPeripheralManager {
        CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: false],
        )
    }

    private func updateAvailability() {
        availability = BluetoothAvailabilityMapper.availability(
            authorization: CBManager.authorization,
            state: peripheralManager?.state,
        )
    }

    private func setupServiceAndAdvertise() {
        guard let configuration = pendingStartConfiguration else { return }
        guard let peripheralManager else { return }

        peripheralManager.removeAllServices()

        let measurement = CBMutableCharacteristic(
            type: CSCSIdentifiers.measurementCharacteristicUUID,
            properties: [.notify],
            value: nil,
            permissions: []
        )
        let feature = CBMutableCharacteristic(
            type: CSCSIdentifiers.featureCharacteristicUUID,
            properties: [.read],
            value: featureValue,
            permissions: [.readable]
        )

        measurementCharacteristic = measurement
        featureCharacteristic = feature

        let service = CBMutableService(type: CSCSIdentifiers.serviceUUID, primary: true)
        service.characteristics = [measurement, feature]
        peripheralManager.add(service)

        _ = configuration
    }

    private func beginAdvertising() {
        guard let peripheralManager else { return }

        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: CSCSIdentifiers.advertisedLocalName,
            CBAdvertisementDataServiceUUIDsKey: [CSCSIdentifiers.serviceUUID],
        ])
    }

    /// Handles the result of `startAdvertising`; exposed for unit tests.
    func handleAdvertisingStartResult(error: Error?) {
        if error != nil {
            lastError = .advertisingFailed
            stop()
            return
        }

        isAdvertising = true
        startNotifyLoop()
    }

    /// Handles the result of adding the CSCS service; exposed for unit tests.
    func handleServiceAdded(error: Error?) {
        if error != nil {
            lastError = .advertisingFailed
            stop()
            return
        }

        beginAdvertising()
    }

    private func startNotifyLoop() {
        notifyTask?.cancel()
        notifyTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: measurementNotifyInterval)
                guard !Task.isCancelled else { break }
                self?.publishMeasurement()
            }
        }
    }

    private func publishMeasurement() {
        guard isAdvertising,
              let peripheralManager,
              let measurementCharacteristic,
              let activeCentral,
              subscriptionTracker.isConnected
        else { return }

        let packet = measurementEncoder.measurement(
            vitals: vitalsProvider(),
            elapsed: measurementNotifyInterval
        )

        let sent = peripheralManager.updateValue(
            packet,
            for: measurementCharacteristic,
            onSubscribedCentrals: [activeCentral]
        )

        if !sent {
            notifyPaused = true
        }
    }

}

extension CSCPeripheralManager: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            updateAvailability()

            if let error = BluetoothStateMapper.error(for: peripheral.state) {
                lastError = error
                stop()
                return
            }

            if pendingStartConfiguration != nil, peripheral.state == .poweredOn {
                setupServiceAndAdvertise()
            }
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        Task { @MainActor in
            handleServiceAdded(error: error)
        }
    }

    nonisolated func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Task { @MainActor in
            handleAdvertisingStartResult(error: error)
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            guard characteristic.uuid == CSCSIdentifiers.measurementCharacteristicUUID else { return }

            if subscriptionTracker.subscribe(central.identifier) {
                activeCentral = central
                isConnected = true
                publishMeasurement()
            }
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            guard characteristic.uuid == CSCSIdentifiers.measurementCharacteristicUUID else { return }

            subscriptionTracker.unsubscribe(central.identifier)
            if !subscriptionTracker.isConnected {
                activeCentral = nil
                isConnected = false
            }
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        Task { @MainActor in
            guard request.characteristic.uuid == CSCSIdentifiers.featureCharacteristicUUID else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
                return
            }

            request.value = featureValue
            peripheral.respond(to: request, withResult: .success)
        }
    }

    nonisolated func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        Task { @MainActor in
            guard notifyPaused else { return }
            notifyPaused = false
            publishMeasurement()
        }
    }
}
