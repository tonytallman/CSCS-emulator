//
//  CoastingModel.swift
//  CSCSEmulator
//

import Foundation

/// Exponential speed decay while coasting (SDD section 9).
struct CoastingModel: Sendable {
    let decayFactor: Double
    let zeroEpsilon: Double

    init(decayFactor: Double = 0.98, zeroEpsilon: Double = 0.01) {
        self.decayFactor = decayFactor
        self.zeroEpsilon = zeroEpsilon
    }

    func decayedSpeed(from speed: Speed) -> Speed {
        let mph = speed.converted(to: .milesPerHour).value
        guard mph > zeroEpsilon else {
            return .stopped
        }

        let decayedMPH = mph * decayFactor
        guard decayedMPH > zeroEpsilon else {
            return .stopped
        }

        return .milesPerHour(decayedMPH)
    }
}
