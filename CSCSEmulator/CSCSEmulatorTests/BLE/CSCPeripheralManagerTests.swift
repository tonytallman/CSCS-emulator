//
//  CSCPeripheralManagerTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct CSCPeripheralManagerTests {
    private func makeManager() -> CSCPeripheralManager {
        CSCPeripheralManager {
            .initial(supportsSpeed: true, supportsCadence: true)
        }
    }

    private var validConfiguration: SimulatorConfiguration {
        SimulatorConfiguration(supportsSpeed: true, supportsCadence: true)
    }

    @Test func serviceAddedDoesNotMarkAdvertisingBeforeConfirmation() {
        let manager = makeManager()
        manager.start(configuration: validConfiguration)

        manager.handleServiceAdded(error: nil)

        #expect(!manager.isAdvertising)
    }

    @Test func advertisingStartSuccessMarksAdvertisingReady() {
        let manager = makeManager()
        manager.start(configuration: validConfiguration)
        manager.handleServiceAdded(error: nil)

        manager.handleAdvertisingStartResult(error: nil)

        #expect(manager.isAdvertising)
        #expect(manager.lastError == nil)
    }

    @Test func advertisingStartFailureRecordsErrorAndCleansUp() {
        let manager = makeManager()
        manager.start(configuration: validConfiguration)
        manager.handleServiceAdded(error: nil)

        manager.handleAdvertisingStartResult(error: TestError.advertisingFailed)

        #expect(!manager.isAdvertising)
        #expect(manager.lastError == .advertisingFailed)
    }

    @Test func serviceAddedFailureRecordsErrorAndCleansUp() {
        let manager = makeManager()
        manager.start(configuration: validConfiguration)

        manager.handleServiceAdded(error: TestError.advertisingFailed)

        #expect(!manager.isAdvertising)
        #expect(manager.lastError == .advertisingFailed)
    }
}

private enum TestError: Error {
    case advertisingFailed
}
