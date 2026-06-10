//
//  PedalingStateTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct PedalingStateTests {
    private func makeState() -> PedalingState {
        PedalingState(vitals: .initial(supportsSpeed: true, supportsCadence: true))
    }

    @Test func acceptsSliderInput() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(25)) as! PedalingState
        let state = afterSpeed.setCadence(.rpm(85)) as! PedalingState

        #expect(state.speed.converted(to: .milesPerHour).value == 25)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 85)
    }

    @Test func clampsSliderInputToRanges() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(100)) as! PedalingState
        let state = afterSpeed.setCadence(.rpm(250)) as! PedalingState

        #expect(state.speed.converted(to: .milesPerHour).value == 50)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 200)
    }

    @Test func tickIsNoOp() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(20)) as! PedalingState
        let updated = afterSpeed.tick() as! PedalingState

        #expect(updated.speed.converted(to: .milesPerHour).value == 20)
        #expect(updated.cadence.converted(to: .revolutionsPerMinute).value == 0)
    }
}
