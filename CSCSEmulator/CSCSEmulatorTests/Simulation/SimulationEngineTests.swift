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
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 1))
        )
    }

    @Test func startSetsRunningAndResetsState() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        #expect(engine.isRunning)
        #expect(engine.state.supportsSpeed)
        #expect(engine.state.supportsCadence)
        #expect(engine.state.mode == .pedaling)
        #expect(engine.state.speed.converted(to: .milesPerHour).value == 0)
        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 0)

        engine.stop()
    }

    @Test func stopClearsRunning() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: false))
        engine.stop()

        #expect(!engine.isRunning)
    }

    @Test func pedalingAcceptsSliderInputAndTickIsNoOp() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        engine.setSpeed(.milesPerHour(25))
        engine.setCadence(.rpm(85))
        engine.tick()

        #expect(engine.state.speed.converted(to: .milesPerHour).value == 25)
        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 85)

        engine.stop()
    }

    @Test func pedalingClampsSliderInputToRanges() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        engine.setSpeed(.milesPerHour(100))
        engine.setCadence(.rpm(250))

        #expect(engine.state.speed.converted(to: .milesPerHour).value == 50)
        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 200)

        engine.stop()
    }

    @Test func sliderInputIgnoredOutsidePedalingMode() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))

        engine.setMode(.coasting)
        engine.setSpeed(.milesPerHour(30))
        engine.setCadence(.rpm(100))

        #expect(engine.state.speed.converted(to: .milesPerHour).value == 0)
        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 0)

        engine.stop()
    }

    @Test func enteringCoastingZerosCadenceAndRetainsSpeed() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        engine.setSpeed(.milesPerHour(28))

        engine.setMode(.coasting)

        #expect(engine.state.cadence.converted(to: .revolutionsPerMinute).value == 0)
        #expect(engine.state.speed.converted(to: .milesPerHour).value == 28)

        engine.stop()
    }

    @Test func coastingTicksDecaySpeedToZero() {
        let engine = makeEngine()
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        engine.setSpeed(.milesPerHour(20))
        engine.setMode(.coasting)

        var previousMPH = engine.state.speed.converted(to: .milesPerHour).value
        for _ in 0..<500 {
            engine.tick()
            let mph = engine.state.speed.converted(to: .milesPerHour).value
            #expect(mph <= previousMPH)
            previousMPH = mph
        }

        #expect(engine.state.speed.converted(to: .milesPerHour).value == 0)

        engine.stop()
    }

    @Test func randomModeAdvancesCadenceAndDerivedSpeed() {
        let engine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 123))
        )
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        engine.setMode(.random)

        let initialCadence = engine.state.cadence.converted(to: .revolutionsPerMinute).value
        for _ in 0..<10 {
            engine.tick()
        }

        let cadenceRPM = engine.state.cadence.converted(to: .revolutionsPerMinute).value
        let speedMPH = engine.state.speed.converted(to: .milesPerHour).value
        let expectedSpeed = cadenceRPM * 20.0 / 90.0

        #expect(cadenceRPM != initialCadence || cadenceRPM == 90)
        #expect(abs(speedMPH - expectedSpeed) < 0.001)

        engine.stop()
    }

    @Test func randomModeAdvancesInternalCadenceWhenCadenceUnsupported() {
        let engine = SimulationEngine(
            coastingModel: CoastingModel(),
            randomCadenceGenerator: RandomCadenceGenerator(rng: SplitMix64(seed: 456))
        )
        engine.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: false))
        engine.setMode(.random)

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
