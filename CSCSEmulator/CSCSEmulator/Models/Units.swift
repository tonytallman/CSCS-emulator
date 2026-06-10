//
//  Units.swift
//  CSCSEmulator
//

import Foundation

typealias Speed = Measurement<UnitSpeed>
typealias Cadence = Measurement<UnitFrequency>

extension UnitFrequency {
    /// Revolutions per minute (RPM = 1/60 Hz).
    static let revolutionsPerMinute = UnitFrequency(
        symbol: "rpm",
        converter: UnitConverterLinear(coefficient: 1.0 / 60.0)
    )
}

extension Speed {
    static func milesPerHour(_ value: Double) -> Speed {
        Speed(value: value, unit: .milesPerHour)
    }
}

extension Cadence {
    static func rpm(_ value: Double) -> Cadence {
        Cadence(value: value, unit: .revolutionsPerMinute)
    }
}

/// Operating ranges from SRS section 3.2.
enum SimulatorRanges {
    static let speedMin = Speed.milesPerHour(0)
    static let speedMax = Speed.milesPerHour(50)
    static let cadenceMin = Cadence.rpm(0)
    static let cadenceMax = Cadence.rpm(200)

    static func clampedSpeed(_ speed: Speed) -> Speed {
        let mph = speed.converted(to: .milesPerHour).value
        let minMPH = speedMin.converted(to: .milesPerHour).value
        let maxMPH = speedMax.converted(to: .milesPerHour).value
        return .milesPerHour(min(max(mph, minMPH), maxMPH))
    }

    static func clampedCadence(_ cadence: Cadence) -> Cadence {
        let rpm = cadence.converted(to: .revolutionsPerMinute).value
        let minRPM = cadenceMin.converted(to: .revolutionsPerMinute).value
        let maxRPM = cadenceMax.converted(to: .revolutionsPerMinute).value
        return .rpm(min(max(rpm, minRPM), maxRPM))
    }
}
