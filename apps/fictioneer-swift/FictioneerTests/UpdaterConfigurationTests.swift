import Foundation
import Testing

/// The test target runs inside the app (TEST_HOST), so Bundle.main is the app
/// bundle — these verify the Sparkle configuration actually shipped.
struct UpdaterConfigurationTests {
    @Test func feedURLPointsAtTheFixedAppcastRelease() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(
            info["SUFeedURL"] as? String
                == "https://github.com/TorstenDittmann/fictioneer/releases/download/appcast/appcast.xml"
        )
    }

    @Test func publicEdDSAKeyIsPresentAndWellFormed() {
        let info = Bundle.main.infoDictionary ?? [:]
        let key = info["SUPublicEDKey"] as? String ?? ""
        #expect(Data(base64Encoded: key)?.count == 32)
    }

    @Test func installerLauncherServiceEnabledForSandbox() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(info["SUEnableInstallerLauncherService"] as? Bool == true)
    }
}
