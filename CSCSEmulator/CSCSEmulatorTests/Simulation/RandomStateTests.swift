//
//  RandomStateTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct RandomStateTests {
    private func makeState(seed: UInt64 = 123) -> RandomState<SplitMix64> {
        RandomState(
            vitals: .initial(supportsSpeed: true, supportsCadence: true),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: seed)),
            internalCadence: .rpm(90),
        )
    }

    @Test func ignoresSliderInput() {
        let afterSpeed = makeState().setSpeed(.milesPerHour(30)) as! RandomState<SplitMix64>
        let state = afterSpeed.setCadence(.rpm(100)) as! RandomState<SplitMix64>

        #expect(state.speed == .stopped)
        #expect(state.cadence == .stopped)
    }

    @Test func tickDoesNotChangeCadenceBeforeOneSecond() {
        let initial = makeState(seed: 123)
        let initialCadence = initial.cadence.converted(to: .revolutionsPerMinute).value
        let initialSpeed = initial.speed.converted(to: .milesPerHour).value

        var state: any SimulatorState = initial
        for _ in 0..<9 {
            state = state.tick()
            #expect(state.cadence.converted(to: .revolutionsPerMinute).value == initialCadence)
            #expect(state.speed.converted(to: .milesPerHour).value == initialSpeed)
        }
    }

    @Test func tickAdvancesCadenceAndDerivedSpeedOncePerSecond() {
        let initial = makeState(seed: 123)
        let initialCadence = initial.cadence.converted(to: .revolutionsPerMinute).value

        var state: any SimulatorState = initial
        for _ in 0..<10 {
            state = state.tick()
        }
        let updated = state as! RandomState<SplitMix64>

        let cadenceRPM = updated.cadence.converted(to: .revolutionsPerMinute).value
        let speedMPH = updated.speed.converted(to: .milesPerHour).value
        let expectedSpeed = cadenceRPM * 20.0 / 90.0

        #expect(cadenceRPM != initialCadence || cadenceRPM == 90)
        #expect(abs(speedMPH - expectedSpeed) < 0.001)
    }

    @Test func tickAdvancesWhenCadenceUnsupported() {
        var state: any SimulatorState = RandomState(
            vitals: .initial(supportsSpeed: true, supportsCadence: false),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 456)),
            internalCadence: .rpm(90),
        )

        for _ in 0..<10 {
            state = state.tick()
        }

        #expect(state.speed.converted(to: .milesPerHour).value > 0)
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
