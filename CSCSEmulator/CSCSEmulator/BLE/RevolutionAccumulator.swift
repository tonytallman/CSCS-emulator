//
//  RevolutionAccumulator.swift
//  CSCSEmulator
//

import Foundation

/// Tracks cumulative revolutions and last event time for CSC Measurement packets (1/1024 s resolution).
struct RevolutionAccumulator: Sendable {
    private(set) var cumulativeRevolutions: UInt32 = 0
    private(set) var lastEventTime1024: UInt16 = 0

    private var fractionalRemainder: Double = 0
    private var absoluteTimeSeconds: Double = 0

    init() {}

    /// Seeds accumulator state for deterministic overflow tests.
    init(
        cumulativeRevolutions: UInt32,
        lastEventTime1024: UInt16 = 0,
        fractionalRemainder: Double = 0,
        absoluteTimeSeconds: Double = 0
    ) {
        self.cumulativeRevolutions = cumulativeRevolutions
        self.lastEventTime1024 = lastEventTime1024
        self.fractionalRemainder = fractionalRemainder
        self.absoluteTimeSeconds = absoluteTimeSeconds
    }

    mutating func accumulate(revolutionsPerSecond: Double, elapsed: Duration) {
        let elapsedSeconds = Self.seconds(from: elapsed)
        guard elapsedSeconds > 0 else { return }

        let intervalStartTime = absoluteTimeSeconds
        absoluteTimeSeconds += elapsedSeconds

        guard revolutionsPerSecond > 0 else { return }

        let remainderAtStart = fractionalRemainder
        let added = revolutionsPerSecond * elapsedSeconds
        let newTotal = remainderAtStart + added
        let wholeNew = Int(newTotal)
        fractionalRemainder = newTotal - Double(wholeNew)

        guard wholeNew > 0 else { return }

        cumulativeRevolutions = cumulativeRevolutions &+ UInt32(wholeNew)
        let timeOfLastRevolution = intervalStartTime + (Double(wholeNew) - remainderAtStart) / revolutionsPerSecond
        lastEventTime1024 = Self.eventTime1024(fromSeconds: timeOfLastRevolution)
    }

    static func seconds(from duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    static func eventTime1024(fromSeconds seconds: Double) -> UInt16 {
        UInt16(truncatingIfNeeded: UInt64(seconds * 1024))
    }
}
