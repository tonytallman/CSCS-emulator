//
//  BluetoothStateMapperTests.swift
//  CSCSEmulatorTests
//

import CoreBluetooth
import Testing
@testable import CSCSEmulator

@Suite struct BluetoothStateMapperTests {
    @Test func unsupportedMapsToUnavailable() {
        #expect(BluetoothStateMapper.error(for: .unsupported) == .bluetoothUnavailable)
    }

    @Test func unauthorizedMapsToUnavailable() {
        #expect(BluetoothStateMapper.error(for: .unauthorized) == .bluetoothUnavailable)
    }

    @Test func poweredOffMapsToDisabled() {
        #expect(BluetoothStateMapper.error(for: .poweredOff) == .bluetoothDisabled)
    }

    @Test func poweredOnMapsToNoError() {
        #expect(BluetoothStateMapper.error(for: .poweredOn) == nil)
    }

    @Test func unknownMapsToNoError() {
        #expect(BluetoothStateMapper.error(for: .unknown) == nil)
    }

    @Test func resettingMapsToNoError() {
        #expect(BluetoothStateMapper.error(for: .resetting) == nil)
    }
}
