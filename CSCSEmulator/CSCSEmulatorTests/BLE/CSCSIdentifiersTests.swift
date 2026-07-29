//
//  CSCSIdentifiersTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct CSCSIdentifiersTests {
    @Test func speedOnlyFeatureValue() {
        let value = CSCSIdentifiers.featureValue(supportsSpeed: true, supportsCadence: false)
        #expect(value.count == 2)
        #expect(value[0] == 0x01)
        #expect(value[1] == 0x00)
    }

    @Test func cadenceOnlyFeatureValue() {
        let value = CSCSIdentifiers.featureValue(supportsSpeed: false, supportsCadence: true)
        #expect(value.count == 2)
        #expect(value[0] == 0x02)
        #expect(value[1] == 0x00)
    }

    @Test func speedAndCadenceFeatureValue() {
        let value = CSCSIdentifiers.featureValue(supportsSpeed: true, supportsCadence: true)
        #expect(value.count == 2)
        #expect(value[0] == 0x03)
        #expect(value[1] == 0x00)
    }

    @Test func advertisedLocalNameIsCSCSEmulator() {
        #expect(CSCSIdentifiers.advertisedLocalName == "CSCS Emulator")
    }
}
