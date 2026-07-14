//
//  AppInfoTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct AppInfoTests {
    @Test func titleMatchesInfoPlist() {
        let expected = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String

        #expect(AppInfo.title == expected)
    }

    @Test func titleIsCSCSEmulator() {
        #expect(AppInfo.title == "CSCS Emulator")
    }
}
