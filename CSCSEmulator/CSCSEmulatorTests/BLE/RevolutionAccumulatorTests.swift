//
//  RevolutionAccumulatorTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct RevolutionAccumulatorTests {
    @Test func constantRateAccumulatesWholeRevolutionsAndEventTime() {
        var accumulator = RevolutionAccumulator()
        accumulator.accumulate(revolutionsPerSecond: 1.5, elapsed: .seconds(2))

        #expect(accumulator.cumulativeRevolutions == 3)
        #expect(accumulator.lastEventTime1024 == 2048)
    }

    @Test func fractionalCarryCompletesRevolutionAcrossTicks() {
        var accumulator = RevolutionAccumulator()

        for _ in 0..<5 {
            accumulator.accumulate(revolutionsPerSecond: 0.4, elapsed: .seconds(1))
        }

        #expect(accumulator.cumulativeRevolutions == 2)
        #expect(accumulator.lastEventTime1024 > 0)
    }

    @Test func zeroRateLeavesCountersUnchanged() {
        var accumulator = RevolutionAccumulator()
        accumulator.accumulate(revolutionsPerSecond: 1.5, elapsed: .seconds(2))
        let revolutions = accumulator.cumulativeRevolutions
        let eventTime = accumulator.lastEventTime1024

        accumulator.accumulate(revolutionsPerSecond: 0, elapsed: .seconds(1))

        #expect(accumulator.cumulativeRevolutions == revolutions)
        #expect(accumulator.lastEventTime1024 == eventTime)
    }

    @Test func counterWrapsViaOverflow() {
        var accumulator = RevolutionAccumulator(cumulativeRevolutions: UInt32.max - 1)
        accumulator.accumulate(revolutionsPerSecond: 10, elapsed: .seconds(1))

        #expect(accumulator.cumulativeRevolutions == 8)
    }

    @Test func eventTimeWrapsViaOverflow() {
        var accumulator = RevolutionAccumulator()
        accumulator.accumulate(revolutionsPerSecond: 1, elapsed: .seconds(65))

        #expect(accumulator.cumulativeRevolutions == 65)
        #expect(accumulator.lastEventTime1024 == RevolutionAccumulator.eventTime1024(fromSeconds: 65))
    }
}
