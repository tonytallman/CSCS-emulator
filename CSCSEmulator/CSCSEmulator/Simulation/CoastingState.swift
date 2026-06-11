//
//  CoastingState.swift
//  CSCSEmulator
//

/// Retains speed on entry with zero cadence; decays speed each tick (SDD section 9).
struct CoastingState: SimulatorState {
    let vitals: SimulatorVitals
    let coastingModel: CoastingModel

    var mode: OperatingMode { .coasting }

    init(vitals: SimulatorVitals, coastingModel: CoastingModel) {
        var updated = vitals
        updated.cadence = .stopped
        self.vitals = updated
        self.coastingModel = coastingModel
    }

    func tick() -> any SimulatorState {
        var updated = vitals
        updated.speed = coastingModel.decayedSpeed(from: vitals.speed)
        return CoastingState(vitals: updated, coastingModel: coastingModel)
    }
}
