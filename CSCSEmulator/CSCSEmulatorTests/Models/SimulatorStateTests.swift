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

        #expect(vitals.speed.converted(to: .milesPerHour).value == 0)
        #expect(vitals.cadence.converted(to: .revolutionsPerMinute).value == 0)
        #expect(vitals.supportsSpeed)
        #expect(vitals.supportsCadence)
    }

    @Test func initialVitalsReflectsConfiguration() {
        let vitals = SimulatorVitals.initial(supportsSpeed: true, supportsCadence: false)

        #expect(vitals.supportsSpeed)
        #expect(!vitals.supportsCadence)
    }

    @Test func pedalingStateExposesVitalsThroughProtocol() {
        let vitals = SimulatorVitals.initial(supportsSpeed: true, supportsCadence: true)
        let state: any SimulatorState = PedalingState(vitals: vitals)

        #expect(state.mode == .pedaling)
        #expect(state.speed.converted(to: .milesPerHour).value == 0)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 0)
        #expect(state.supportsSpeed)
        #expect(state.supportsCadence)
    }
}
