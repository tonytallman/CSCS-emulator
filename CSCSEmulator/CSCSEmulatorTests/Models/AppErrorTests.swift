//
//  AppErrorTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct AppErrorTests {
    @Test func bluetoothUnavailableHasUserFacingDescription() {
        let description = AppError.bluetoothUnavailable.errorDescription
        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test func bluetoothDisabledHasUserFacingDescription() {
        let description = AppError.bluetoothDisabled.errorDescription
        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test func bluetoothPermissionDeniedReferencesAppName() {
        let english = Locale(components: Locale.Components(languageCode: Locale.LanguageCode("en")))
        let displayName = String(localized: "Bike Sensor", locale: english)
        let description = AppError.bluetoothPermissionDenied.errorDescription
        #expect(description?.contains(displayName) == true)
    }

    @Test func advertisingFailedHasUserFacingDescription() {
        let description = AppError.advertisingFailed.errorDescription
        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test func connectionFailedHasUserFacingDescription() {
        let description = AppError.connectionFailed.errorDescription
        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test func internalErrorHasUserFacingDescription() {
        let description = AppError.internalError.errorDescription
        #expect(description != nil)
        #expect(!description!.isEmpty)
    }
}
