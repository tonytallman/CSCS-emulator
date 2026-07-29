//
//  RandomState.swift
//  CSCSEmulator
//

import Foundation

/// Simulation ticks at 10 Hz; random cadence updates every tick.
private let randomCadenceUpdateIntervalTicks = 1

/// Bounded random-walk cadence with derived speed; user input ignored (SDD section 10).
struct RandomState<RNG: RandomNumberGenerator>: SimulatorState {
    var vitals: SimulatorVitals
    var randomCadenceGenerator: RandomCadenceGenerator<RNG>
    var internalCadence: Cadence
    var ticksSinceLastCadenceUpdate: Int

    var mode: OperatingMode { .random }

    init(
        vitals: SimulatorVitals,
        randomCadenceGenerator: RandomCadenceGenerator<RNG>,
        internalCadence: Cadence,
        ticksSinceLastCadenceUpdate: Int = 0,
    ) {
        self.vitals = vitals
        self.randomCadenceGenerator = randomCadenceGenerator
        self.internalCadence = internalCadence
        self.ticksSinceLastCadenceUpdate = ticksSinceLastCadenceUpdate
    }

    func tick() -> any SimulatorState {
        let nextTickCount = ticksSinceLastCadenceUpdate + 1
        guard nextTickCount >= randomCadenceUpdateIntervalTicks else {
            return RandomState(
                vitals: vitals,
                randomCadenceGenerator: randomCadenceGenerator,
                internalCadence: internalCadence,
                ticksSinceLastCadenceUpdate: nextTickCount,
            )
        }

        var updatedGenerator = randomCadenceGenerator
        let nextCadence = updatedGenerator.nextCadence(after: internalCadence)
        var updatedVitals = vitals
        updatedVitals.cadence = nextCadence
        updatedVitals.speed = updatedGenerator.derivedSpeed(from: nextCadence)
        return RandomState(
            vitals: updatedVitals,
            randomCadenceGenerator: updatedGenerator,
            internalCadence: nextCadence,
            ticksSinceLastCadenceUpdate: 0,
        )
    }
}
