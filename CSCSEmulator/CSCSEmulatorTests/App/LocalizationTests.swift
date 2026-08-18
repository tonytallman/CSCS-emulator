//
//  LocalizationTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct LocalizationTests {
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

    private static let startEmulatorTranslations: [String: String] = [
        "es": "Iniciar emulador",
        "zh-Hans": "启动模拟器",
        "zh-Hant": "啟動模擬器",
        "ja": "エミュレーターを開始",
        "de": "Emulator starten",
        "fr": "Démarrer l'émulateur",
        "pt-BR": "Iniciar emulador",
        "ko": "에뮬레이터 시작",
        "it": "Avvia emulatore",
    ]

    private static let titleTranslations: [String: String] = [
        "es": "Emulador de sensor de bicicleta",
        "zh-Hans": "自行车传感器模拟器",
        "zh-Hant": "自行車感測器模擬器",
        "ja": "自転車センサーエミュレーター",
        "de": "Fahrradsensor-Emulator",
        "fr": "Émulateur de capteur vélo",
        "pt-BR": "Emulador de sensor de bicicleta",
        "ko": "자전거 센서 에뮬레이터",
        "it": "Emulatore sensore bici",
    ]

    private static let displayNameTranslations: [String: String] = [
        "es": "Sensor de bicicleta",
        "zh-Hans": "自行车传感器",
        "zh-Hant": "自行車感測器",
        "ja": "自転車センサー",
        "de": "Fahrradsensor",
        "fr": "Capteur vélo",
        "pt-BR": "Sensor de bicicleta",
        "ko": "자전거 센서",
        "it": "Sensore bici",
    ]

    private static let speedTranslations: [String: String] = [
        "es": "Velocidad",
        "zh-Hans": "速度",
        "zh-Hant": "速度",
        "ja": "速度",
        "de": "Geschwindigkeit",
        "fr": "Vitesse",
        "pt-BR": "Velocidade",
        "ko": "속도",
        "it": "Velocità",
    ]

    private static let cadenceTranslations: [String: String] = [
        "es": "Cadencia",
        "zh-Hans": "踏频",
        "zh-Hant": "踏頻",
        "ja": "ケイデンス",
        "de": "Trittfrequenz",
        "fr": "Cadence",
        "pt-BR": "Cadência",
        "ko": "케이던스",
        "it": "Cadenza",
    ]

    private static let supportSpeedTranslations: [String: String] = [
        "es": "Admitir velocidad (mph)",
        "zh-Hans": "支持速度 (mph)",
        "zh-Hant": "支援速度 (mph)",
        "ja": "速度をサポート (mph)",
        "de": "Geschwindigkeit unterstützen (mph)",
        "fr": "Prendre en charge la vitesse (mph)",
        "pt-BR": "Suportar velocidade (mph)",
        "ko": "속도 지원 (mph)",
        "it": "Supporta velocità (mph)",
    ]

    private static let supportCadenceTranslations: [String: String] = [
        "es": "Admitir cadencia (rpm)",
        "zh-Hans": "支持踏频 (rpm)",
        "zh-Hant": "支援踏頻 (rpm)",
        "ja": "ケイデンスをサポート (rpm)",
        "de": "Trittfrequenz unterstützen (rpm)",
        "fr": "Prendre en charge la cadence (tr/min)",
        "pt-BR": "Suportar cadência (rpm)",
        "ko": "케이던스 지원 (rpm)",
        "it": "Supporta cadenza (rpm)",
    ]

    private static let advertisingFailedTranslations: [String: String] = [
        "de": "BLE-Advertising konnte nicht gestartet werden. Bitte versuche es erneut.",
        "es": "No se pudo iniciar la difusión BLE. Inténtalo de nuevo.",
        "it": "Impossibile avviare la trasmissione BLE. Riprova.",
        "pt-BR": "Não foi possível iniciar a transmissão BLE. Tente novamente.",
        "ko": "BLE 어드버타이징을 시작하지 못했습니다. 다시 시도해 주세요.",
    ]

    private static let infoPlistDisplayNameTranslations: [String: String] = [
        "es": "Sensor de bicicleta",
        "zh-Hans": "自行车传感器",
        "zh-Hant": "自行車感測器",
        "ja": "自転車センサー",
        "de": "Fahrradsensor",
        "fr": "Capteur vélo",
        "pt-BR": "Sensor de bicicleta",
        "ko": "자전거 센서",
        "it": "Sensore bici",
    ]

    private static let infoPlistPermissionTranslations: [String: String] = [
        "en": "Advertises a simulated cycling speed and cadence sensor.",
        "de": "Stellt über Bluetooth einen simulierten Fahrrad-Geschwindigkeits- und Trittfrequenzsensor bereit.",
        "es": "Proporciona por Bluetooth un sensor simulado de velocidad y cadencia de ciclismo.",
        "fr": "Fournit via Bluetooth un capteur simulé de vitesse et de cadence cyclistes.",
        "it": "Fornisce tramite Bluetooth un sensore simulato di velocità e cadenza per il ciclismo.",
        "ja": "シミュレートされた自転車の速度・ケイデンスセンサーをアドバタイズします。",
        "pt-BR": "Disponibiliza via Bluetooth um sensor simulado de velocidade e cadência de ciclismo.",
        "ko": "시뮬레이션된 자전거 속도 및 케이던스 센서를 BLE로 어드버타이징합니다.",
        "zh-Hans": "广播模拟的骑行速度与踏频传感器。",
        "zh-Hant": "廣播模擬的騎行速度與踏頻感測器。",
    ]

    private static let bleNameTranslations: [String: String] = [
        "es": "Emulador CSCS",
        "zh-Hans": "CSCS 模拟器",
        "zh-Hant": "CSCS 模擬器",
        "ja": "CSCSエミュレーター",
        "de": "CSCS-Emulator",
        "fr": "Émulateur CSCS",
        "pt-BR": "Emulador CSCS",
        "ko": "CSCS 에뮬레이터",
        "it": "Emulatore CSCS",
    ]

    private static let errorDescriptionKeys = [
        "Bluetooth is not available on this device.",
        "Bluetooth is turned off. Enable Bluetooth in Settings to use the emulator.",
        "Bluetooth permission is turned off. Enable Bluetooth access for %@ in Settings to start the emulator.",
        "Failed to start BLE advertising. Please try again.",
        "A BLE connection could not be established.",
        "An unexpected error occurred. Please try again.",
    ]

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

    private func catalogURL(named name: String) throws -> URL {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0 ..< 8 {
            let candidate = directory.appendingPathComponent("CSCSEmulator/\(name).xcstrings")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            directory.deleteLastPathComponent()
        }
        throw LocalizationCatalogError.missingCatalog(name)
    }

    private func loadCatalog(named name: String) throws -> [String: Any] {
        let data = try Data(contentsOf: catalogURL(named: name))
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw LocalizationCatalogError.invalidFormat(name)
        }
        return dictionary
    }

    private func localizedValue(
        in catalog: [String: Any],
        key: String,
        localeIdentifier: String,
    ) -> String? {
        guard
            let strings = catalog["strings"] as? [String: Any],
            let entry = strings[key] as? [String: Any],
            let localizations = entry["localizations"] as? [String: Any],
            let localeEntry = localizations[localeIdentifier] as? [String: Any],
            let stringUnit = localeEntry["stringUnit"] as? [String: Any],
            let value = stringUnit["value"] as? String
        else {
            return nil
        }
        return value
    }

    private func expectCatalogTranslation(
        catalog: [String: Any],
        key: String,
        localeIdentifier: String,
        expected: String?,
    ) {
        let translation = localizedValue(in: catalog, key: key, localeIdentifier: localeIdentifier)
        #expect(translation == expected)
        if let expected, expected != key {
            #expect(translation != key)
        }
    }

    @Test(arguments: supportedLocales)
    func startEmulatorIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Start Emulator",
            localeIdentifier: localeIdentifier,
            expected: Self.startEmulatorTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func inAppTitleIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Bike Sensor Emulator",
            localeIdentifier: localeIdentifier,
            expected: Self.titleTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func displayNameIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Bike Sensor",
            localeIdentifier: localeIdentifier,
            expected: Self.displayNameTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func configurationSpeedLabelIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Speed",
            localeIdentifier: localeIdentifier,
            expected: Self.speedTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func configurationCadenceLabelIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Cadence",
            localeIdentifier: localeIdentifier,
            expected: Self.cadenceTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func configurationSupportSpeedSubtitleIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Support speed (mph)",
            localeIdentifier: localeIdentifier,
            expected: Self.supportSpeedTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func configurationSupportCadenceSubtitleIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Support cadence (rpm)",
            localeIdentifier: localeIdentifier,
            expected: Self.supportCadenceTranslations[localeIdentifier],
        )
    }

    @Test func rpmUnitIsTrMinInFrench() throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "rpm",
            localeIdentifier: "fr",
            expected: "tr/min",
        )
    }

    @Test(arguments: supportedLocales)
    func bleAdvertisedNameContainsCSCSAndIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        let translation = localizedValue(
            in: catalog,
            key: "CSCS Emulator",
            localeIdentifier: localeIdentifier,
        )
        #expect(translation?.contains("CSCS") == true)
        #expect(translation == Self.bleNameTranslations[localeIdentifier])
    }

    @Test(arguments: Array(advertisingFailedTranslations.keys))
    func advertisingFailedUsesTechnicalBLEWording(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        expectCatalogTranslation(
            catalog: catalog,
            key: "Failed to start BLE advertising. Please try again.",
            localeIdentifier: localeIdentifier,
            expected: Self.advertisingFailedTranslations[localeIdentifier],
        )
    }

    @Test(arguments: supportedLocales)
    func bluetoothPermissionDeniedFormatsDisplayName(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        let template = localizedValue(
            in: catalog,
            key: "Bluetooth permission is turned off. Enable Bluetooth access for %@ in Settings to start the emulator.",
            localeIdentifier: localeIdentifier,
        )
        let displayName = localizedValue(
            in: catalog,
            key: "Bike Sensor",
            localeIdentifier: localeIdentifier,
        )
        guard let template, let displayName else {
            Issue.record("Missing bluetooth permission or display name translation for \(localeIdentifier)")
            return
        }

        let formatted = String(format: template, displayName)
        #expect(formatted.contains(displayName))
        #expect(formatted.contains("%@") == false)
        #expect(!formatted.isEmpty)
    }

    @Test(arguments: supportedLocales)
    func errorDescriptionsAreTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "Localizable")
        for key in Self.errorDescriptionKeys {
            let translation = localizedValue(in: catalog, key: key, localeIdentifier: localeIdentifier)
            #expect(translation?.isEmpty == false)
            #expect(translation != key)
        }
    }

    @Test func appInfoResolvesEnglishStringsFromCatalog() {
        let english = locale(for: "en")
        #expect(String(localized: "Bike Sensor Emulator", locale: english) == "Bike Sensor Emulator")
        #expect(String(localized: "Bike Sensor", locale: english) == "Bike Sensor")
        #expect(!AppInfo.title.isEmpty)
        #expect(!AppInfo.displayName.isEmpty)
    }

    @Test(arguments: supportedLocales)
    func infoPlistDisplayNameIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "InfoPlist")
        expectCatalogTranslation(
            catalog: catalog,
            key: "CFBundleDisplayName",
            localeIdentifier: localeIdentifier,
            expected: Self.infoPlistDisplayNameTranslations[localeIdentifier],
        )
    }

    @Test(arguments: Array(infoPlistPermissionTranslations.keys))
    func infoPlistBluetoothPermissionIsTranslated(localeIdentifier: String) throws {
        let catalog = try loadCatalog(named: "InfoPlist")
        expectCatalogTranslation(
            catalog: catalog,
            key: "NSBluetoothAlwaysUsageDescription",
            localeIdentifier: localeIdentifier,
            expected: Self.infoPlistPermissionTranslations[localeIdentifier],
        )
    }

    @Test func localizableCatalogHasNoStaleKeys() throws {
        let catalog = try loadCatalog(named: "Localizable")
        guard let strings = catalog["strings"] as? [String: Any] else {
            Issue.record("Localizable.xcstrings is missing strings")
            return
        }

        for (key, value) in strings {
            guard let entry = value as? [String: Any] else { continue }
            let extractionState = entry["extractionState"] as? String
            #expect(
                extractionState != "stale",
                "Expected \(key) to be current, found stale extraction state",
            )
        }
    }

    @Test func localizableCatalogCoversAllSupportedLocales() throws {
        let catalog = try loadCatalog(named: "Localizable")
        guard let strings = catalog["strings"] as? [String: Any] else {
            Issue.record("Localizable.xcstrings is missing strings")
            return
        }

        for (key, value) in strings {
            guard
                let entry = value as? [String: Any],
                let localizations = entry["localizations"] as? [String: Any]
            else {
                Issue.record("Missing localizations for \(key)")
                continue
            }

            for localeIdentifier in Self.supportedLocales {
                guard let localeEntry = localizations[localeIdentifier] as? [String: Any] else {
                    Issue.record("Missing \(localeIdentifier) localization for \(key)")
                    continue
                }

                let stringUnit = localeEntry["stringUnit"] as? [String: Any]
                let state = stringUnit?["state"] as? String
                let translation = stringUnit?["value"] as? String

                #expect(state == "translated", "Expected translated state for \(key) in \(localeIdentifier)")
                #expect(translation?.isEmpty == false)
            }
        }
    }

    @Test func infoPlistCatalogHasNoNewLocalizationStates() throws {
        let catalog = try loadCatalog(named: "InfoPlist")
        guard let strings = catalog["strings"] as? [String: Any] else {
            Issue.record("InfoPlist.xcstrings is missing strings")
            return
        }

        for (key, value) in strings {
            guard
                let entry = value as? [String: Any],
                let localizations = entry["localizations"] as? [String: Any]
            else {
                continue
            }

            for (localeIdentifier, localeValue) in localizations {
                guard
                    let localeEntry = localeValue as? [String: Any],
                    let stringUnit = localeEntry["stringUnit"] as? [String: Any],
                    let state = stringUnit["state"] as? String
                else {
                    continue
                }

                #expect(
                    state != "new",
                    "Expected no new localization state for \(key) in \(localeIdentifier)",
                )
            }
        }
    }

    @Test func bluetoothPermissionTemplatePreservesPlaceholderInEveryLocale() throws {
        let catalog = try loadCatalog(named: "Localizable")
        let key = "Bluetooth permission is turned off. Enable Bluetooth access for %@ in Settings to start the emulator."
        for localeIdentifier in Self.supportedLocales {
            let translation = localizedValue(in: catalog, key: key, localeIdentifier: localeIdentifier)
            #expect(translation?.contains("%@") == true)
        }
    }
}

private enum LocalizationCatalogError: Error {
    case invalidFormat(String)
    case missingCatalog(String)
}
