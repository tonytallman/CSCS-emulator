//
//  CoastingModelTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct CoastingModelTests {
    private let model = CoastingModel()

    @Test func speedDecaysEachTick() {
        let initial = Speed.milesPerHour(20)
        let decayed = model.decayedSpeed(from: initial)
        #expect(decayed.converted(to: .milesPerHour).value < 20)
    }

    @Test func speedNeverIncreases() {
        let initial = Speed.milesPerHour(15)
        let decayed = model.decayedSpeed(from: initial)
        #expect(decayed.converted(to: .milesPerHour).value <= 15)
    }

    @Test func repeatedDecayReachesZero() {
        var speed = Speed.milesPerHour(20)
        for _ in 0..<500 {
            speed = model.decayedSpeed(from: speed)
        }
        #expect(speed.converted(to: .milesPerHour).value == 0)
    }

    @Test func zeroSpeedStaysZero() {
        let zero = Speed.milesPerHour(0)
        #expect(model.decayedSpeed(from: zero).converted(to: .milesPerHour).value == 0)
    }
}
