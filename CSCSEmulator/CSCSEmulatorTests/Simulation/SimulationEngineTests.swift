//
//  SimulationEngineTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct SimulationEngineTests {
    private func makeEngine() -> SimulationEngine<SplitMix64> {
        SimulationEngine(
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 1)),
        )
    }

    @Test func startSetsRunningAndRandomMode() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        #expect(engine.isRunning)
        #expect(engine.state.supportsSpeed)
        #expect(engine.state.supportsCadence)
        #expect(engine.state.mode == .random)
        #expect(engine.state.speed == .stopped)
        #expect(engine.state.cadence == .stopped)

        engine.stop()
    }

    @Test func stopClearsRunning() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: false))
        engine.stop()

        #expect(!engine.isRunning)
    }

    @Test func manualAcceptsSliderInputAndTickIsNoOp() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        engine.setMode(.manual)

        engine.setSpeed(.milesPerHour(25))
        engine.setCadence(.rpm(85))
        engine.tick()

        #expect(engine.state.speed.converted(to: .milesPerHour).value == 25)
        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 85)

        engine.stop()
    }

    @Test func manualClampsSliderInputToRanges() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        engine.setMode(.manual)

        engine.setSpeed(.milesPerHour(100))
        engine.setCadence(.rpm(250))

        #expect(engine.state.speed.converted(to: .milesPerHour).value == 50)
        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 200)

        engine.stop()
    }

    @Test func sliderInputIgnoredOutsideManualMode() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        engine.setSpeed(.milesPerHour(30))
        engine.setCadence(.rpm(100))

        #expect(engine.state.speed == .stopped)
        #expect(engine.state.cadence == .stopped)

        engine.stop()
    }

    @Test func randomModeAdvancesCadenceAndDerivedSpeed() {
        let engine = SimulationEngine(
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 123)),
        )
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        let initialCadence = engine.state.cadence.converted(to: .revolutionsPerMinute).value
        for _ in 0..<10 {
            engine.tick()
        }

        let cadenceRPM = engine.state.cadence.converted(to: .revolutionsPerMinute).value
        let speedMPH = engine.state.speed.converted(to: .milesPerHour).value
        let expectedSpeed = cadenceRPM * 50.0 / 200.0

        #expect(cadenceRPM != initialCadence || cadenceRPM == 90)
        #expect(abs(speedMPH - expectedSpeed) < 0.001)

        engine.stop()
    }

    @Test func randomModeAdvancesInternalCadenceWhenCadenceUnsupported() {
        let engine = SimulationEngine(
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 456)),
        )
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: false))

        for _ in 0..<10 {
            engine.tick()
        }

        #expect(engine.state.speed.converted(to: .milesPerHour).value > 0)

        engine.stop()
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
