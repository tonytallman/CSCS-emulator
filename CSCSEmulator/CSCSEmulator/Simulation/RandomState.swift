//
//  RandomState.swift
//  CSCSEmulator
//

import Foundation

/// Bounded random-walk cadence with derived speed; user input ignored (SDD section 10).
/// Cadence updates once per engine tick (1 Hz).
struct RandomState<RNG: RandomNumberGenerator>: SimulatorState {
    var vitals: SimulatorVitals
    var randomCadenceGenerator: RandomCadenceGenerator<RNG>
    var internalCadence: Cadence

    var mode: OperatingMode { .random }

    init(
        vitals: SimulatorVitals,
        randomCadenceGenerator: RandomCadenceGenerator<RNG>,
        internalCadence: Cadence,
    ) {
        self.vitals = vitals
        self.randomCadenceGenerator = randomCadenceGenerator
        self.internalCadence = internalCadence
    }

    func tick() -> any SimulatorState {
        var updatedGenerator = randomCadenceGenerator
        let nextCadence = updatedGenerator.nextCadence(after: internalCadence)
        var updatedVitals = vitals
        updatedVitals.cadence = nextCadence
        updatedVitals.speed = updatedGenerator.derivedSpeed(from: nextCadence)
        return RandomState(
            vitals: updatedVitals,
            randomCadenceGenerator: updatedGenerator,
            internalCadence: nextCadence,
        )
    }
}
