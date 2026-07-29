//
//  ManualStateTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct ManualStateTests {
    private func makeState() -> ManualState {
        ManualState(vitals: .initial(supportsSpeed: true, supportsCadence: true))
    }

    @Test func acceptsSliderInput() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(25)) as! ManualState
        let state = afterSpeed.setCadence(.rpm(85)) as! ManualState

        #expect(state.speed.converted(to: .milesPerHour).value == 25)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 85)
    }

    @Test func clampsSliderInputToRanges() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(100)) as! ManualState
        let state = afterSpeed.setCadence(.rpm(250)) as! ManualState

        #expect(state.speed.converted(to: .milesPerHour).value == 50)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 200)
    }

    @Test func tickIsNoOp() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(20)) as! ManualState
        let updated = afterSpeed.tick() as! ManualState

        #expect(updated.speed.converted(to: .milesPerHour).value == 20)
        #expect(updated.cadence == .stopped)
    }
}
