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

        let settings = AppSettings(defaults: defaults)
        #expect(settings.spellcheckEnabled == true)
        settings.spellcheckEnabled = false

        let reloaded = AppSettings(defaults: defaults)
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

        let settings = AppSettings(defaults: defaults)
        #expect(settings.spellcheckEnabled == true)
    }
}
