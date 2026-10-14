//
//  RevolutionCountersTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite(.timeLimit(.minutes(1))) struct RevolutionCountersTests {
    @Test func speedHandVector() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: false),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(0),
            supportsSpeed: true,
            supportsCadence: false,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(1))
        let speedMetersPerSecond = Speed.milesPerHour(20).converted(to: .metersPerSecond).value
        let wheelRevolutionsPerSecond = speedMetersPerSecond / 2.105
        let expectedRevolutions: UInt32 = 4
        let expectedEventTime = RevolutionAccumulator.eventTime1024(
            fromSeconds: Double(expectedRevolutions) / wheelRevolutionsPerSecond,
        )
        #expect(sample?.wheel?.cumulativeRevolutions == expectedRevolutions)
        #expect(sample?.wheel?.lastEventTime == expectedEventTime)
        #expect(sample?.crank == nil)
    }

    @Test func cadenceHandVector() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: false, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(0),
            cadence: .rpm(90),
            supportsSpeed: false,
            supportsCadence: true,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(2))
        #expect(sample?.crank?.cumulativeRevolutions == 3)
        #expect(sample?.crank?.lastEventTime == 0x0800)
        #expect(sample?.wheel == nil)
    }

    @Test func cumulativeCountersIncreaseAcrossSuccessiveCalls() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        _ = counters.advance(vitals: vitals, elapsed: .seconds(1))
        let second = counters.advance(vitals: vitals, elapsed: .seconds(1))
        let third = counters.advance(vitals: vitals, elapsed: .seconds(1))
        #expect(second?.wheel?.cumulativeRevolutions == 8)
        #expect(third?.wheel?.cumulativeRevolutions == 12)
        #expect(second?.crank?.cumulativeRevolutions == 3)
        #expect(third?.crank?.cumulativeRevolutions == 4)
    }

    @Test func movingCadenceSkipsTicksWhenCountDoesNotAdvance() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: false, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .stopped,
            cadence: .rpm(30),
            supportsSpeed: false,
            supportsCadence: true,
        )
        #expect(counters.advance(vitals: vitals, elapsed: .seconds(1)) == nil)
        let second = counters.advance(vitals: vitals, elapsed: .seconds(1))
        #expect(second?.crank?.cumulativeRevolutions == 1)
        #expect(counters.advance(vitals: vitals, elapsed: .seconds(1)) == nil)
    }

    @Test func zeroSpeedAndCadenceReturnsNil() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true),
        )
        let moving = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        _ = counters.advance(vitals: moving, elapsed: .seconds(1))
        let stopped = SimulatorVitals(
            speed: .stopped,
            cadence: .stopped,
            supportsSpeed: true,
            supportsCadence: true,
        )
        #expect(counters.advance(vitals: stopped, elapsed: .seconds(1)) == nil)
    }

    @Test func zeroCadenceWithSpeedReturnsWheelOnly() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .stopped,
            supportsSpeed: true,
            supportsCadence: true,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(1))
        #expect(sample?.wheel != nil)
        #expect(sample?.crank == nil)
    }

    @Test func unsupportedMetricHalfIsNil() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: false),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(1))
        #expect(sample?.wheel != nil)
        #expect(sample?.crank == nil)
    }

    @Test func halvesFollowConfigurationNotVitalsFlags() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: false,
            supportsCadence: false,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(1))
        #expect(sample?.wheel != nil)
        #expect(sample?.crank != nil)
    }

    @Test func crankTruncatesToUInt16() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: false, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .stopped,
            cadence: .rpm(200),
            supportsSpeed: false,
            supportsCadence: true,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(20_000))
        #expect(sample?.crank?.cumulativeRevolutions == 1_130)
    }

    @Test func bothMetricsReturnBothHalvesInOneSample() {
        var counters = RevolutionCounters(
            configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true),
        )
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        let sample = counters.advance(vitals: vitals, elapsed: .seconds(1))
        #expect(sample?.wheel != nil)
        #expect(sample?.crank != nil)
    }
}
