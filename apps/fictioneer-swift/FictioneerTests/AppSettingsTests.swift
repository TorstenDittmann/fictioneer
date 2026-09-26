import Foundation
import Testing
@testable import Fictioneer

struct AppSettingsTests {
    @Test func persistedLocalhostMigratesToProductionInRelease() {
        #expect(
            AppSettings.migratedURL(AppConfig.debugIntelligenceBaseURL, isDebug: false)
                == AppConfig.productionIntelligenceBaseURL
        )
    }

    @Test func persistedLocalhostStaysInDebug() {
        #expect(
            AppSettings.migratedURL(AppConfig.debugIntelligenceBaseURL, isDebug: true)
                == AppConfig.debugIntelligenceBaseURL
        )
    }

    @Test func customURLIsPreserved() {
        let custom = "https://staging.example.com:8080"
        #expect(AppSettings.migratedURL(custom, isDebug: false) == custom)
        #expect(AppSettings.migratedURL(custom, isDebug: true) == custom)
    }

    @Test func spellcheckEnabledRoundTripsThroughPersistence() {
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.spellcheckEnabled == true)
        settings.spellcheckEnabled = false

        let reloaded = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(reloaded.spellcheckEnabled == false)
    }

    @Test func snapshotWithoutSpellcheckFieldDecodesToEnabled() throws {
        // Simulates a settings blob persisted before spellcheckEnabled existed.
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let legacyJSON = """
        {
            "theme": "system",
            "editorFontFamily": "\(FontLoader.defaultEditorFamily)",
            "editorFontSize": 18,
            "editorLineHeight": 1.75,
            "intelligenceURLString": "\(AppConfig.defaultIntelligenceBaseURL)",
            "licenseKey": ""
        }
        """
        defaults.set(Data(legacyJSON.utf8), forKey: "fictioneer.settings")

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.spellcheckEnabled == true)
    }

    @Test func upsellDismissedRoundTripsThroughPersistence() {
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.upsellDismissed == false)
        settings.upsellDismissed = true

        let reloaded = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(reloaded.upsellDismissed == true)
    }

    @Test func snapshotWithoutUpsellDismissedFieldDecodesToFalse() throws {
        // Simulates a settings blob persisted before upsellDismissed existed.
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let legacyJSON = """
        {
            "theme": "system",
            "editorFontFamily": "\(FontLoader.defaultEditorFamily)",
            "editorFontSize": 18,
            "editorLineHeight": 1.75,
            "intelligenceURLString": "\(AppConfig.defaultIntelligenceBaseURL)",
            "licenseKey": ""
        }
        """
        defaults.set(Data(legacyJSON.utf8), forKey: "fictioneer.settings")

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.upsellDismissed == false)
    }

    @Test func exportDefaultsRoundTripThroughPersistence() {
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.exportDefaults == nil)

        let stored = ExportDefaults(
            format: .epub,
            includeTitle: false,
            includeChapterTitles: true,
            includeSceneTitles: false,
            includeWordCount: true,
            epubTemplate: .modernCompact
        )
        settings.exportDefaults = stored

        let reloaded = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(reloaded.exportDefaults == stored)
    }

    @Test func invalidExportDefaultsDegradesWithoutWipingOtherSettings() throws {
        // A future app version could persist an ExportDefaults with an enum
        // rawValue this build doesn't know. That must degrade exportDefaults
        // to nil — not fail the whole snapshot and reset every setting
        // (including the license key).
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let blob = """
        {
            "theme": "dark",
            "editorFontFamily": "\(FontLoader.defaultEditorFamily)",
            "editorFontSize": 21,
            "editorLineHeight": 1.5,
            "intelligenceURLString": "\(AppConfig.defaultIntelligenceBaseURL)",
            "licenseKey": "LICENSE-123",
            "exportDefaults": {
                "format": "holographic_scroll",
                "includeTitle": true,
                "includeChapterTitles": true,
                "includeSceneTitles": true,
                "includeWordCount": false,
                "epubTemplate": "generic_novel"
            }
        }
        """
        defaults.set(Data(blob.utf8), forKey: "fictioneer.settings")

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.licenseKey == "LICENSE-123")
        #expect(settings.theme == .dark)
        #expect(settings.editorFontSize == 21)
        #expect(settings.exportDefaults == nil)
    }

    @Test func snapshotWithoutExportDefaultsFieldDecodesToNil() throws {
        // Simulates a settings blob persisted before exportDefaults existed.
        let suiteName = "app-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let legacyJSON = """
        {
            "theme": "system",
            "editorFontFamily": "\(FontLoader.defaultEditorFamily)",
            "editorFontSize": 18,
            "editorLineHeight": 1.75,
            "intelligenceURLString": "\(AppConfig.defaultIntelligenceBaseURL)",
            "licenseKey": ""
        }
        """
        defaults.set(Data(legacyJSON.utf8), forKey: "fictioneer.settings")

        let settings = AppSettings(defaults: defaults, secrets: InMemorySecretStore())
        #expect(settings.exportDefaults == nil)
    }

    @Test func licenseKeyIsStoredInSecretsNotDefaults() throws {
        let defaults = UserDefaults(suiteName: "app-settings-\(UUID().uuidString)")!
        let secrets = InMemorySecretStore()

        let settings = AppSettings(defaults: defaults, secrets: secrets)
        settings.licenseKey = "LICENSE-456"
        settings.theme = .dark

        #expect(secrets.string(forKey: "license-key") == "LICENSE-456")
        let blob = try #require(defaults.data(forKey: "fictioneer.settings"))
        #expect(!String(decoding: blob, as: UTF8.self).contains("LICENSE-456"))
        #expect(AppSettings(defaults: defaults, secrets: secrets).licenseKey == "LICENSE-456")
    }

    @Test func legacyPlaintextLicenseKeyMigratesToSecrets() throws {
        let defaults = UserDefaults(suiteName: "app-settings-\(UUID().uuidString)")!
        let secrets = InMemorySecretStore()
        let legacyJSON = """
        {
            "theme": "system",
            "editorFontFamily": "\(FontLoader.defaultEditorFamily)",
            "editorFontSize": 18,
            "editorLineHeight": 1.75,
            "intelligenceURLString": "\(AppConfig.defaultIntelligenceBaseURL)",
            "licenseKey": "LEGACY-KEY"
        }
        """
        defaults.set(Data(legacyJSON.utf8), forKey: "fictioneer.settings")

        let settings = AppSettings(defaults: defaults, secrets: secrets)
        #expect(settings.licenseKey == "LEGACY-KEY")
        #expect(secrets.string(forKey: "license-key") == "LEGACY-KEY")
        let blob = try #require(defaults.data(forKey: "fictioneer.settings"))
        #expect(!String(decoding: blob, as: UTF8.self).contains("LEGACY-KEY"))
    }

    @Test func clearingLicenseKeyRemovesSecret() {
        let secrets = InMemorySecretStore()
        let settings = AppSettings(
            defaults: UserDefaults(suiteName: "app-settings-\(UUID().uuidString)")!,
            secrets: secrets
        )
        settings.licenseKey = "LICENSE-789"
        settings.licenseKey = ""
        #expect(secrets.string(forKey: "license-key") == nil)
    }
}
