//
//  SimulationEngine.swift
//  CSCSEmulator
//

import Foundation
import Observation

private let simulationTickInterval: Duration = .milliseconds(100)

/// Owns simulator state and executes mode-specific updates at a fixed interval (SDD section 7).
@Observable
@MainActor
final class SimulationEngine<RNG: RandomNumberGenerator> {

    private(set) var state: any SimulatorState
    private(set) var isRunning = false

    private let coastingModel: CoastingModel
    private var randomCadenceGenerator: RandomCadenceGenerator<RNG>
    private var tickTask: Task<Void, Never>?

    init(
        coastingModel: CoastingModel,
        randomCadenceGenerator: RandomCadenceGenerator<RNG>,
    ) {
        self.state = PedalingState(vitals: .initial(supportsSpeed: false, supportsCadence: false))
        self.coastingModel = coastingModel
        self.randomCadenceGenerator = randomCadenceGenerator
    }

    func start(configuration: SimulatorConfiguration) {
        guard configuration.isValid else { return }

        stop()
        state = PedalingState(
            vitals: .initial(
                supportsSpeed: configuration.supportsSpeed,
                supportsCadence: configuration.supportsCadence,
            )
        )
        isRunning = true

        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: simulationTickInterval)
                guard !Task.isCancelled else { break }
                self?.tick()
            }
        }
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
        isRunning = false
    }

    func setMode(_ mode: OperatingMode) {
        syncRandomCadenceGeneratorFromState()
        state = makeState(for: mode, from: state.vitals)
    }

    func setSpeed(_ speed: Speed) {
        state = state.setSpeed(speed)
    }

    func setCadence(_ cadence: Cadence) {
        state = state.setCadence(cadence)
    }

    /// Advances simulation by one tick. Separated from scheduling for deterministic tests.
    func tick() {
        state = state.tick()
        syncRandomCadenceGeneratorFromState()
    }

    private func makeState(for mode: OperatingMode, from vitals: SimulatorVitals) -> any SimulatorState {
        switch mode {
        case .pedaling:
            return PedalingState(vitals: vitals)
        case .coasting:
            var coastingVitals = vitals
            coastingVitals.cadence = .rpm(0)
            return CoastingState(vitals: coastingVitals, coastingModel: coastingModel)
        case .random:
            return RandomState(
                vitals: vitals,
                randomCadenceGenerator: randomCadenceGenerator,
                internalCadence: seededRandomCadence(from: vitals.cadence),
            )
        }
    }

    private func seededRandomCadence(from cadence: Cadence) -> Cadence {
        let rpm = cadence.converted(to: .revolutionsPerMinute).value
        if rpm > 0 {
            return cadence
        }
        return .rpm(90)
    }

    private func syncRandomCadenceGeneratorFromState() {
        if let randomState = state as? RandomState<RNG> {
            randomCadenceGenerator = randomState.randomCadenceGenerator
        }
    }
}
