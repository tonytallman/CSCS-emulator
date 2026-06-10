//
//  RandomCadenceGenerator.swift
//  CSCSEmulator
//

import Foundation

/// Bounded random-walk cadence generator with weak bias toward 90 RPM (SDD section 10).
struct RandomCadenceGenerator<RNG: RandomNumberGenerator> {
    var rng: RNG

    init(rng: RNG) {
        self.rng = rng
    }

    mutating func nextCadence(after cadence: Cadence) -> Cadence {
        let rpm = cadence.converted(to: .revolutionsPerMinute).value
        let randomDelta = Double.random(in: -2...2, using: &rng)
        let biasToward90 = (90 - rpm) * 0.02
        let newRPM = min(
            max(rpm + randomDelta + biasToward90, SimulatorRanges.cadenceMin.converted(to: .revolutionsPerMinute).value),
            SimulatorRanges.cadenceMax.converted(to: .revolutionsPerMinute).value
        )
        return .rpm(newRPM)
    }

    func derivedSpeed(from cadence: Cadence) -> Speed {
        let rpm = cadence.converted(to: .revolutionsPerMinute).value
        let mph = rpm * 20.0 / 90.0
        return .milesPerHour(mph)
    }
}
