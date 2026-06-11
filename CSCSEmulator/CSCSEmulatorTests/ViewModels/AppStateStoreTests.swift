//
//  AppStateStoreTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct AppStateStoreTests {
    @Test func initialStateIsConfiguring() {
        let store = AppStateStore()

        #expect(store.state == .configuring)
    }

    @Test func enterRunningSetsStateToRunning() {
        let store = AppStateStore()

        store.enterRunning()

        #expect(store.state == .running)
    }

    @Test func enterConfiguringSetsStateToConfiguring() {
        let store = AppStateStore()
        store.enterRunning()

        store.enterConfiguring()

        #expect(store.state == .configuring)
    }
}
