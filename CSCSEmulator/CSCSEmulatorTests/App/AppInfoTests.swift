//
//  AppInfoTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct AppInfoTests {
    private var english: Locale {
        Locale(components: Locale.Components(languageCode: Locale.LanguageCode("en")))
    }

    @Test func titleResolvesFromStringCatalogInEnglish() {
        #expect(
            String(localized: "Bike Sensor Emulator", locale: english)
                == "Bike Sensor Emulator"
        )
        #expect(!AppInfo.title.isEmpty)
    }

    @Test func displayNameResolvesFromStringCatalogInEnglish() {
        #expect(
            String(localized: "Bike Sensor", locale: english)
                == "Bike Sensor"
        )
        #expect(!AppInfo.displayName.isEmpty)
    }
}
