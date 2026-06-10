//
//  SimulatorStateTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct SimulatorStateTests {
    @Test func initialStateDefaults() {
        let state = SimulatorState.initial(supportsSpeed: true, supportsCadence: true)

        #expect(state.mode == .pedaling)
        #expect(state.speed.converted(to: .milesPerHour).value == 0)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 0)
        #expect(state.supportsSpeed)
        #expect(state.supportsCadence)
        #expect(!state.isRunning)
    }

    @Test func initialStateReflectsConfiguration() {
        let state = SimulatorState.initial(supportsSpeed: true, supportsCadence: false)

        #expect(state.supportsSpeed)
        #expect(!state.supportsCadence)
    }
}
