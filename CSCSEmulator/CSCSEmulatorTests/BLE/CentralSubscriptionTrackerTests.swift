//
//  CentralSubscriptionTrackerTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct CentralSubscriptionTrackerTests {
    @Test func firstSubscriberIsAccepted() {
        var tracker = CentralSubscriptionTracker()
        let centralID = UUID()

        let accepted = tracker.subscribe(centralID)
        #expect(accepted)
        #expect(tracker.isConnected)
        #expect(tracker.isActive(centralID))
    }

    @Test func secondSubscriberRejectedWhileFirstActive() {
        var tracker = CentralSubscriptionTracker()
        let first = UUID()
        let second = UUID()

        let firstAccepted = tracker.subscribe(first)
        let secondAccepted = tracker.subscribe(second)
        #expect(firstAccepted)
        #expect(!secondAccepted)
        #expect(tracker.activeCentralID == first)
    }

    @Test func unsubscribeActiveCentralFreesSlot() {
        var tracker = CentralSubscriptionTracker()
        let first = UUID()
        let second = UUID()

        _ = tracker.subscribe(first)
        tracker.unsubscribe(first)

        #expect(!tracker.isConnected)
        let secondAccepted = tracker.subscribe(second)
        #expect(secondAccepted)
        #expect(tracker.activeCentralID == second)
    }

    @Test func unsubscribeNonActiveCentralIsNoOp() {
        var tracker = CentralSubscriptionTracker()
        let active = UUID()
        let other = UUID()

        _ = tracker.subscribe(active)
        tracker.unsubscribe(other)

        #expect(tracker.activeCentralID == active)
    }

    @Test func resubscribeSameCentralIsAccepted() {
        var tracker = CentralSubscriptionTracker()
        let centralID = UUID()

        let firstAccepted = tracker.subscribe(centralID)
        let secondAccepted = tracker.subscribe(centralID)
        #expect(firstAccepted)
        #expect(secondAccepted)
        #expect(tracker.activeCentralID == centralID)
    }
}
