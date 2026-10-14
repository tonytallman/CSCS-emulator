//
//  RevolutionCounters.swift
//  CSCSEmulator
//

import Foundation

struct RevolutionCounters: Sendable {
    struct Sample: Equatable, Sendable {
        struct Wheel: Equatable, Sendable {
            let cumulativeRevolutions: UInt32
            let lastEventTime: UInt16
        }

        struct Crank: Equatable, Sendable {
            let cumulativeRevolutions: UInt16
            let lastEventTime: UInt16
        }

        let wheel: Wheel?
        let crank: Crank?
    }

    private let supportsSpeed: Bool
    private let supportsCadence: Bool
    private let wheelCircumferenceMeters: Double
    private var wheelAccumulator = RevolutionAccumulator()
    private var crankAccumulator = RevolutionAccumulator()

    init(
        configuration: SimulatorConfiguration,
        wheelCircumference: Measurement<UnitLength> = .init(value: 2.105, unit: .meters),
    ) {
        supportsSpeed = configuration.supportsSpeed
        supportsCadence = configuration.supportsCadence
        wheelCircumferenceMeters = wheelCircumference.converted(to: .meters).value
    }

    /// Returns only the halves whose revolution count advanced, or nil when neither did.
    mutating func advance(vitals: SimulatorVitals, elapsed: Duration) -> Sample? {
        var wheelSample: Sample.Wheel?
        var crankSample: Sample.Crank?

        if supportsSpeed {
            let before = wheelAccumulator.cumulativeRevolutions
            let speedMetersPerSecond = vitals.speed.converted(to: .metersPerSecond).value
            let wheelRevolutionsPerSecond = speedMetersPerSecond / wheelCircumferenceMeters
            wheelAccumulator.accumulate(revolutionsPerSecond: wheelRevolutionsPerSecond, elapsed: elapsed)
            if wheelAccumulator.cumulativeRevolutions != before {
                wheelSample = Sample.Wheel(
                    cumulativeRevolutions: wheelAccumulator.cumulativeRevolutions,
                    lastEventTime: wheelAccumulator.lastEventTime1024,
                )
            }
        }

        if supportsCadence {
            let before = crankAccumulator.cumulativeRevolutions
            let crankRevolutionsPerSecond = vitals.cadence.converted(to: .hertz).value
            crankAccumulator.accumulate(revolutionsPerSecond: crankRevolutionsPerSecond, elapsed: elapsed)
            if crankAccumulator.cumulativeRevolutions != before {
                let crankRevolutions = UInt16(truncatingIfNeeded: crankAccumulator.cumulativeRevolutions)
                crankSample = Sample.Crank(
                    cumulativeRevolutions: crankRevolutions,
                    lastEventTime: crankAccumulator.lastEventTime1024,
                )
            }
        }

        if wheelSample == nil, crankSample == nil {
            return nil
        }
        return Sample(wheel: wheelSample, crank: crankSample)
    }
}
