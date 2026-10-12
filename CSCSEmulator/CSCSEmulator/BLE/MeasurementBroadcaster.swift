//
//  MeasurementBroadcaster.swift
//  CSCSEmulator
//

import CoreBluetooth
import Foundation
import Observation
import os

private let measurementNotifyInterval: Duration = .seconds(1)

@Observable
@MainActor
final class MeasurementBroadcaster: MeasurementBroadcasting {
    private(set) var isAdvertising = false
    private(set) var isConnected = false
    private(set) var lastError: AppError?
    private(set) var availability: BluetoothAvailability = .ready
    private(set) var runTask: Task<Void, Never>?

    private static let logger = Logger(subsystem: "com.tallmansoftware.csc-emulator", category: "BLE")

    #if DEBUG
    private var suppressBluetoothAvailabilityCheck: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
    #else
    private let suppressBluetoothAvailabilityCheck = false
    #endif

    private let bluetooth: any BluetoothStateMonitoring
    private let makeServer: (SimulatorConfiguration) -> any MeasurementServer
    private let vitalsProvider: () -> SimulatorVitals
    private var server: (any MeasurementServer)?
    private var counters: RevolutionCounters?
    private var notifyTask: Task<Void, Never>?

    init(
        bluetooth: any BluetoothStateMonitoring,
        makeServer: @escaping (SimulatorConfiguration) -> any MeasurementServer,
        vitalsProvider: @escaping () -> SimulatorVitals,
    ) {
        self.bluetooth = bluetooth
        self.makeServer = makeServer
        self.vitalsProvider = vitalsProvider
        bluetooth.onStateChange = { [weak self] in self?.handleStateChange($0) }
    }

    func prepare() {
        if bluetooth.authorization != .notDetermined {
            bluetooth.activate()
        }
        updateAvailability()
    }

    func refreshAvailability() {
        prepare()
    }

    func start(configuration: SimulatorConfiguration) {
        guard configuration.isValid else { return }
        stop()
        lastError = nil
        bluetooth.activate()
        counters = RevolutionCounters(configuration: configuration)
        let server = makeServer(configuration)
        self.server = server
        let previous = runTask
        runTask = Task { await run(server, after: previous) }
        updateAvailability()
    }

    func stop() {
        runTask?.cancel()
        notifyTask?.cancel()
        notifyTask = nil
        server = nil
        counters = nil
        isAdvertising = false
        isConnected = false
        updateAvailability()
    }

    func publishSample() {
        guard isConnected, let server,
              let sample = counters?.advance(vitals: vitalsProvider(), elapsed: measurementNotifyInterval)
        else { return }
        server.publish(sample)
    }

    private func run(_ server: any MeasurementServer, after previous: Task<Void, Never>?) async {
        await previous?.value
        do {
            try Task.checkCancellation()
            try await server.start()
            try Task.checkCancellation()
            isAdvertising = true
            startNotifyLoop()
            // The count stream never finishes on its own; cancellation ends it, possibly after one more element.
            for await count in await server.subscriberCount {
                guard !Task.isCancelled else { break }
                updateConnection(subscriberCount: count)
            }
        } catch {
            if !Task.isCancelled {
                Self.logger.error("CSCServer start failed: \(String(describing: error), privacy: .public)")
                lastError = BluetoothAvailabilityMapper.availability(
                    authorization: bluetooth.authorization,
                    state: bluetooth.state,
                ).appError ?? .advertisingFailed
            }
        }
        await server.stop()
    }

    private func startNotifyLoop() {
        notifyTask?.cancel()
        notifyTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: measurementNotifyInterval)
                guard !Task.isCancelled else { break }
                self?.publishSample()
            }
        }
    }

    private func updateAvailability() {
        if suppressBluetoothAvailabilityCheck {
            availability = .ready
            return
        }
        availability = BluetoothAvailabilityMapper.availability(
            authorization: bluetooth.authorization,
            state: bluetooth.state,
        )
    }

    private func handleStateChange(_ state: CBManagerState) {
        updateAvailability()
        if suppressBluetoothAvailabilityCheck {
            return
        }
        if let error = BluetoothStateMapper.error(for: state) {
            lastError = error
            stop()
        }
    }

    private func updateConnection(subscriberCount: Int) {
        let wasConnected = isConnected
        isConnected = subscriberCount > 0
        if isConnected, !wasConnected {
            publishSample()
        }
    }
}
