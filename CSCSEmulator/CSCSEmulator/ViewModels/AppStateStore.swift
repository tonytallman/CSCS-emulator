//
//  AppStateStore.swift
//  CSCSEmulator
//

import Foundation
import Observation

@Observable
@MainActor
final class AppStateStore {
    private(set) var state: AppState = .configuring

    func enterRunning() {
        state = .running
    }

    func enterConfiguring() {
        state = .configuring
    }
}
