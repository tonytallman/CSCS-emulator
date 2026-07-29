//
//  RandomCadenceGeneratorTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

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

@Suite struct RandomCadenceGeneratorTests {
    @Test func successiveValuesChangeByBoundedAmount() {
        var generator = RandomCadenceGenerator(rng: SplitMix64(seed: 42))
        var cadence = Cadence.rpm(90)

        for _ in 0..<50 {
            let previousRPM = cadence.converted(to: .revolutionsPerMinute).value
            cadence = generator.nextCadence(after: cadence)
            let delta = abs(cadence.converted(to: .revolutionsPerMinute).value - previousRPM)
            #expect(delta <= 2.0)
        }
    }

    @Test func outputStaysWithinOperatingRange() {
        var generator = RandomCadenceGenerator(rng: SplitMix64(seed: 99))
        var cadence = Cadence.rpm(90)

        for _ in 0..<200 {
            cadence = generator.nextCadence(after: cadence)
            let rpm = cadence.converted(to: .revolutionsPerMinute).value
            #expect(rpm >= 0)
            #expect(rpm <= 200)
        }
    }

    @Test func weakBiasDriftsUpwardFromLowCadence() {
        var generator = RandomCadenceGenerator(rng: SplitMix64(seed: 7))
        var cadence = Cadence.rpm(45)
        var sum = 0.0

        for _ in 0..<100 {
            cadence = generator.nextCadence(after: cadence)
            sum += cadence.converted(to: .revolutionsPerMinute).value
        }

        let average = sum / 100.0
        #expect(average > 45)
    }

    @Test func weakBiasDriftsDownwardFromHighCadence() {
        var generator = RandomCadenceGenerator(rng: SplitMix64(seed: 13))
        var cadence = Cadence.rpm(135)
        var sum = 0.0

        for _ in 0..<100 {
            cadence = generator.nextCadence(after: cadence)
            sum += cadence.converted(to: .revolutionsPerMinute).value
        }

        let average = sum / 100.0
        #expect(average < 135)
    }

    @Test func derivedSpeedMatchesSRSTable() {
        let generator = RandomCadenceGenerator(rng: SplitMix64(seed: 1))

        let speedAt45 = generator.derivedSpeed(from: .rpm(45))
        #expect(abs(speedAt45.converted(to: .milesPerHour).value - 11.25) < 0.001)

        let speedAt90 = generator.derivedSpeed(from: .rpm(90))
        #expect(abs(speedAt90.converted(to: .milesPerHour).value - 22.5) < 0.001)

        let speedAt135 = generator.derivedSpeed(from: .rpm(135))
        #expect(abs(speedAt135.converted(to: .milesPerHour).value - 33.75) < 0.001)
    }
}
