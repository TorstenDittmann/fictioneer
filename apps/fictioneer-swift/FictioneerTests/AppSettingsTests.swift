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
}
