//
//  SimulatorStateTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct SimulatorStateTests {
    @Test func initialVitalsDefaults() {
        let vitals = SimulatorVitals.initial(supportsSpeed: true, supportsCadence: true)

        #expect(vitals.speed == .stopped)
        #expect(vitals.cadence == .stopped)
        #expect(vitals.supportsSpeed)
        #expect(vitals.supportsCadence)
    }

    @Test func initialVitalsReflectsConfiguration() {
        let vitals = SimulatorVitals.initial(supportsSpeed: true, supportsCadence: false)

        #expect(vitals.supportsSpeed)
        #expect(!vitals.supportsCadence)
    }

    @Test func manualStateExposesVitalsThroughProtocol() {
        let vitals = SimulatorVitals.initial(supportsSpeed: true, supportsCadence: true)
        let state: any SimulatorState = ManualState(vitals: vitals)

        #expect(state.mode == .manual)
        #expect(state.speed == .stopped)
        #expect(state.cadence == .stopped)
        #expect(state.supportsSpeed)
        #expect(state.supportsCadence)
    }
}
