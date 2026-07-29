//
//  ManualState.swift
//  CSCSEmulator
//

/// User-controlled speed and cadence; no automatic updates on tick (SDD section 8).
struct ManualState: SimulatorState {
    let vitals: SimulatorVitals

    var mode: OperatingMode { .manual }

    init(vitals: SimulatorVitals) {
        self.vitals = vitals
    }

    func setSpeed(_ speed: Speed) -> any SimulatorState {
        var updated = vitals
        updated.speed = SimulatorRanges.clampedSpeed(speed)
        return ManualState(vitals: updated)
    }

    func setCadence(_ cadence: Cadence) -> any SimulatorState {
        var updated = vitals
        updated.cadence = SimulatorRanges.clampedCadence(cadence)
        return ManualState(vitals: updated)
    }
}
