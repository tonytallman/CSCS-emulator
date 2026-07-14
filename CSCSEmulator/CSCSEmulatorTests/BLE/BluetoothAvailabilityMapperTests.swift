//
//  BluetoothAvailabilityMapperTests.swift
//  CSCSEmulatorTests
//

import CoreBluetooth
import Testing
@testable import CSCSEmulator

@Suite struct BluetoothAvailabilityMapperTests {
    @Test func deniedAuthorizationMapsToPermissionDenied() {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .denied,
                state: nil,
            ) == .permissionDenied
        )
    }

    @Test func restrictedAuthorizationMapsToPermissionDenied() {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .restricted,
                state: nil,
            ) == .permissionDenied
        )
    }

    @Test func notDeterminedAuthorizationMapsToReady() {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .notDetermined,
                state: nil,
            ) == .ready
        )
    }

    @Test func allowedAlwaysWithNilStateMapsToReady() {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .allowedAlways,
                state: nil,
            ) == .ready
        )
    }

    @Test(arguments: [
        CBManagerState.poweredOn,
        .unknown,
        .resetting,
    ])
    func allowedAlwaysWithOperationalStateMapsToReady(state: CBManagerState) {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .allowedAlways,
                state: state,
            ) == .ready
        )
    }

    @Test func allowedAlwaysWithPoweredOffMapsToPoweredOff() {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .allowedAlways,
                state: .poweredOff,
            ) == .poweredOff
        )
    }

    @Test(arguments: [
        CBManagerState.unsupported,
        .unauthorized,
    ])
    func allowedAlwaysWithUnavailableStateMapsToUnavailable(state: CBManagerState) {
        #expect(
            BluetoothAvailabilityMapper.availability(
                authorization: .allowedAlways,
                state: state,
            ) == .unavailable
        )
    }
}
