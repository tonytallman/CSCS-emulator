//
//  SimulatorConfigurationTests.swift
//  CSCSEmulatorTests
//

import Testing
@testable import CSCSEmulator

@Suite struct SimulatorConfigurationTests {
    @Test func speedOnlyIsValid() {
        let config = SimulatorConfiguration(supportsSpeed: true, supportsCadence: false)
        #expect(config.isValid)
    }

    @Test func cadenceOnlyIsValid() {
        let config = SimulatorConfiguration(supportsSpeed: false, supportsCadence: true)
        #expect(config.isValid)
    }

    @Test func speedAndCadenceIsValid() {
        let config = SimulatorConfiguration(supportsSpeed: true, supportsCadence: true)
        #expect(config.isValid)
    }

    @Test func neitherMetricIsInvalid() {
        let config = SimulatorConfiguration(supportsSpeed: false, supportsCadence: false)
        #expect(!config.isValid)
    }
}
