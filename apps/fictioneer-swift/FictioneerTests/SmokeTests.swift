import Testing
@testable import Fictioneer

struct SmokeTests {
    @Test func appConfigDefaults() {
        #expect(AppConfig.formatVersion == 1)
        #expect(AppConfig.ghostTextWordCount == 36)
        #expect(AppConfig.checkoutURL.absoluteString == "https://fictioneer.app/checkout")
        #expect(AppConfig.accountURL.absoluteString == "https://fictioneer.app/account")
    }
}
