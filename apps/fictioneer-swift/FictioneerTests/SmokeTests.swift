import Testing
@testable import Fictioneer

struct SmokeTests {
    @Test func appConfigDefaults() {
        #expect(AppConfig.formatVersion == 1)
        #expect(AppConfig.ghostTextWordCount == 36)
    }
}
