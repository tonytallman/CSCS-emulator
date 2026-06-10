//
//  UnitsTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct UnitsTests {
    @Test func revolutionsPerMinuteSymbol() {
        #expect(UnitFrequency.revolutionsPerMinute.symbol == "rpm")
    }

    @Test func ninetyRPMEqualsOnePointFiveHertz() {
        let cadence = Cadence.rpm(90)
        let hertz = cadence.converted(to: .hertz)
        #expect(hertz.value == 1.5)
    }

    @Test func cadenceRoundTripRPMToHertzAndBack() {
        let original = Cadence.rpm(120)
        let roundTripped = Measurement(
            value: original.converted(to: .hertz).value,
            unit: UnitFrequency.hertz
        ).converted(to: .revolutionsPerMinute)
        #expect(roundTripped.value == 120)
    }

    @Test func speedMilesPerHourConvertsToKilometersPerHour() {
        let speed = Speed.milesPerHour(20)
        let kmh = speed.converted(to: .kilometersPerHour).value
        #expect(abs(kmh - 32.18688) < 0.001)
    }

    @Test func simulatorRangeConstantsMatchSRS() {
        #expect(SimulatorRanges.speedMin.converted(to: .milesPerHour).value == 0)
        #expect(SimulatorRanges.speedMax.converted(to: .milesPerHour).value == 50)
        #expect(SimulatorRanges.cadenceMin.converted(to: .revolutionsPerMinute).value == 0)
        #expect(SimulatorRanges.cadenceMax.converted(to: .revolutionsPerMinute).value == 200)
    }
}
