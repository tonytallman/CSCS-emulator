//
//  CoastingStateTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct CoastingStateTests {
    private func makeState(speed: Speed = .milesPerHour(20)) -> CoastingState {
        var vitals = SimulatorVitals.initial(supportsSpeed: true, supportsCadence: true)
        vitals.speed = speed
        return CoastingState(vitals: vitals, coastingModel: CoastingModel())
    }

    @Test func ignoresSliderInput() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(30)) as! CoastingState
        let state = afterSpeed.setCadence(.rpm(100)) as! CoastingState

        #expect(state.speed.converted(to: .milesPerHour).value == 20)
        #expect(state.cadence.converted(to: .revolutionsPerMinute).value == 0)
    }

    @Test func tickDecaysSpeedToZero() {
        var state: any SimulatorState = makeState()

        var previousMPH = state.speed.converted(to: .milesPerHour).value
        for _ in 0..<500 {
            state = state.tick()
            let mph = state.speed.converted(to: .milesPerHour).value
            #expect(mph <= previousMPH)
            previousMPH = mph
        }

        #expect(state.speed.converted(to: .milesPerHour).value == 0)
    }
}
