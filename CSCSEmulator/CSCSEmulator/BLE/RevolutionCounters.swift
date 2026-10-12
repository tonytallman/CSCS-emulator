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

    init(
        configuration: SimulatorConfiguration,
        wheelCircumference: Measurement<UnitLength> = .init(value: 2.105, unit: .meters),
    ) {
        _ = configuration
        _ = wheelCircumference
    }

    mutating func advance(vitals: SimulatorVitals, elapsed: Duration) -> Sample? {
        nil
    }
}
