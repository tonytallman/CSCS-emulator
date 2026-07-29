//
//  AppInfoTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct AppInfoTests {
    @Test func titleIsBikeSensorEmulator() {
        #expect(AppInfo.title == "Bike Sensor Emulator")
    }

    @Test func homeScreenDisplayNameIsBikeSensor() {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String

        #expect(displayName == "Bike Sensor")
    }
}
