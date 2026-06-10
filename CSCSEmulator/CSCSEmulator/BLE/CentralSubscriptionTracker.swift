//
//  CentralSubscriptionTracker.swift
//  CSCSEmulator
//

import Foundation

/// Enforces at most one active CSC Measurement subscriber (SDD section 12).
struct CentralSubscriptionTracker: Sendable {
    private(set) var activeCentralID: UUID?

    var isConnected: Bool {
        activeCentralID != nil
    }

    mutating func subscribe(_ id: UUID) -> Bool {
        if let activeCentralID, activeCentralID != id {
            return false
        }
        activeCentralID = id
        return true
    }

    mutating func unsubscribe(_ id: UUID) {
        guard activeCentralID == id else { return }
        activeCentralID = nil
    }

    func isActive(_ id: UUID) -> Bool {
        activeCentralID == id
    }

    mutating func reset() {
        activeCentralID = nil
    }
}
