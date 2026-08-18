//
//  CSCSIdentifiersTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct CSCSIdentifiersTests {
    private static let supportedLocales = [
        "es",
        "zh-Hans",
        "zh-Hant",
        "ja",
        "de",
        "fr",
        "pt-BR",
        "ko",
        "it",
    ]

    @Test func speedOnlyFeatureValue() {
        let value = CSCSIdentifiers.featureValue(supportsSpeed: true, supportsCadence: false)
        #expect(value.count == 2)
        #expect(value[0] == 0x01)
        #expect(value[1] == 0x00)
    }

    @Test func cadenceOnlyFeatureValue() {
        let value = CSCSIdentifiers.featureValue(supportsSpeed: false, supportsCadence: true)
        #expect(value.count == 2)
        #expect(value[0] == 0x02)
        #expect(value[1] == 0x00)
    }

    @Test func speedAndCadenceFeatureValue() {
        let value = CSCSIdentifiers.featureValue(supportsSpeed: true, supportsCadence: true)
        #expect(value.count == 2)
        #expect(value[0] == 0x03)
        #expect(value[1] == 0x00)
    }

    private func locale(for identifier: String) -> Locale {
        switch identifier {
        case "zh-Hans":
            Locale(components: Locale.Components(
                languageCode: Locale.LanguageCode("zh"),
                script: Locale.Script("Hans"),
            ))
        case "zh-Hant":
            Locale(components: Locale.Components(
                languageCode: Locale.LanguageCode("zh"),
                script: Locale.Script("Hant"),
            ))
        case "pt-BR":
            Locale(components: Locale.Components(
                languageCode: Locale.LanguageCode("pt"),
                languageRegion: Locale.Region("BR"),
            ))
        default:
            Locale(components: Locale.Components(languageCode: Locale.LanguageCode(identifier)))
        }
    }

    @Test func advertisedLocalNameResolvesFromStringCatalogInEnglish() {
        let english = locale(for: "en")
        #expect(
            String(localized: "CSCS Emulator", locale: english)
                == "CSCS Emulator"
        )
        #expect(CSCSIdentifiers.advertisedLocalName.contains("CSCS"))
    }

    @Test(arguments: supportedLocales)
    func advertisedLocalNameContainsCSCSInEveryLocale(localeIdentifier: String) {
        let name = String(
            localized: String.LocalizationValue("CSCS Emulator"),
            locale: locale(for: localeIdentifier),
        )
        #expect(name.contains("CSCS"))
    }
}
