import Foundation
import SwiftUI

/// Persisted export window preferences (format and manuscript include
/// toggles). Everything about the book itself lives on the project.
nonisolated struct ExportDefaults: Codable, Equatable {
    var format: ExportFormat
    var includeTitle: Bool
    var includeChapterTitles: Bool
    var includeSceneTitles: Bool
    var includeWordCount: Bool
    /// Legacy: templates are per project now (`BookSettings.template`).
    var epubTemplate: EpubTemplate?
}

@Observable
final class AppSettings {
    enum Theme: String, Codable, CaseIterable, Identifiable {
        case system, light, dark

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    var theme: Theme = .system { didSet { persist() } }
    var editorFontFamily: String = FontLoader.defaultEditorFamily { didSet { persist() } }
    var editorFontSize: Double = 18 { didSet { persist() } }
    var editorLineHeight: Double = 1.75 { didSet { persist() } }
    var intelligenceURLString: String = AppConfig.defaultIntelligenceBaseURL { didSet { persist() } }
    /// Kept in the Keychain, never in the preferences blob.
    var licenseKey: String = "" {
        didSet {
            guard !isLoading else { return }
            secrets.set(licenseKey, forKey: Self.licenseKeyAccount)
        }
    }
    /// Prose-analysis inline highlights (off by default, matching the Tauri app).
    var proseHighlightsEnabled: Bool = false { didSet { persist() } }
    /// Raw values of visible AnalysisType cases; empty means "all".
    var visibleAnalysisTypes: [String] = [] { didSet { persist() } }
    var spellcheckEnabled: Bool = true { didSet { persist() } }
    /// Focus mode fades every paragraph except the one being written.
    var dimsParagraphsInFocusMode: Bool = true { didSet { persist() } }
    var exportDefaults: ExportDefaults? { didSet { persist() } }
    /// Set once the welcome-screen license upsell card is dismissed; the card never returns.
    var upsellDismissed: Bool = false { didSet { persist() } }

    private nonisolated struct Snapshot: Codable {
        var theme: Theme
        var editorFontFamily: String
        var editorFontSize: Double
        var editorLineHeight: Double
        var intelligenceURLString: String
        /// Legacy: read once to migrate into the Keychain, never written.
        var licenseKey: String?
        var proseHighlightsEnabled: Bool?
        var visibleAnalysisTypes: [String]?
        var spellcheckEnabled: Bool?
        var exportDefaults: ExportDefaults?
        var upsellDismissed: Bool?
        var dimsParagraphsInFocusMode: Bool?

        init(
            theme: Theme,
            editorFontFamily: String,
            editorFontSize: Double,
            editorLineHeight: Double,
            intelligenceURLString: String,
            proseHighlightsEnabled: Bool?,
            visibleAnalysisTypes: [String]?,
            spellcheckEnabled: Bool?,
            exportDefaults: ExportDefaults?,
            upsellDismissed: Bool?,
            dimsParagraphsInFocusMode: Bool?
        ) {
            self.theme = theme
            self.editorFontFamily = editorFontFamily
            self.editorFontSize = editorFontSize
            self.editorLineHeight = editorLineHeight
            self.intelligenceURLString = intelligenceURLString
            self.licenseKey = nil
            self.proseHighlightsEnabled = proseHighlightsEnabled
            self.visibleAnalysisTypes = visibleAnalysisTypes
            self.spellcheckEnabled = spellcheckEnabled
            self.exportDefaults = exportDefaults
            self.upsellDismissed = upsellDismissed
            self.dimsParagraphsInFocusMode = dimsParagraphsInFocusMode
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            theme = try container.decode(Theme.self, forKey: .theme)
            editorFontFamily = try container.decode(String.self, forKey: .editorFontFamily)
            editorFontSize = try container.decode(Double.self, forKey: .editorFontSize)
            editorLineHeight = try container.decode(Double.self, forKey: .editorLineHeight)
            intelligenceURLString = try container.decode(String.self, forKey: .intelligenceURLString)
            licenseKey = try container.decodeIfPresent(String.self, forKey: .licenseKey)
            proseHighlightsEnabled = try container.decodeIfPresent(Bool.self, forKey: .proseHighlightsEnabled)
            visibleAnalysisTypes = try container.decodeIfPresent([String].self, forKey: .visibleAnalysisTypes)
            spellcheckEnabled = try container.decodeIfPresent(Bool.self, forKey: .spellcheckEnabled)
            // Deliberately lenient: ExportDefaults nests non-optional enums,
            // so an unknown rawValue written by a future version must degrade
            // to nil — not fail the whole snapshot and wipe every setting
            // (including the license key).
            exportDefaults = try? container.decodeIfPresent(ExportDefaults.self, forKey: .exportDefaults)
            upsellDismissed = try container.decodeIfPresent(Bool.self, forKey: .upsellDismissed)
            dimsParagraphsInFocusMode = try container.decodeIfPresent(Bool.self, forKey: .dimsParagraphsInFocusMode)
        }
    }

    private static let defaultsKey = "fictioneer.settings"
    private static let licenseKeyAccount = "license-key"
    private let defaults: UserDefaults
    private let secrets: SecretStore
    private var isLoading = false

    init(defaults: UserDefaults = .standard, secrets: SecretStore = KeychainSecretStore()) {
        self.defaults = defaults
        self.secrets = secrets
        load()
    }

    var intelligenceBaseURL: URL {
        URL(string: intelligenceURLString) ?? URL(string: AppConfig.defaultIntelligenceBaseURL)!
    }

    /// Installs that persisted the old localhost default must not pin release
    /// builds to localhost forever; user-customized URLs are preserved.
    nonisolated static func migratedURL(_ persisted: String, isDebug: Bool) -> String {
        guard !isDebug, persisted == AppConfig.debugIntelligenceBaseURL else { return persisted }
        return AppConfig.productionIntelligenceBaseURL
    }

    private nonisolated static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private func load() {
        isLoading = true
        licenseKey = secrets.string(forKey: Self.licenseKeyAccount) ?? ""
        isLoading = false
        guard let data = defaults.data(forKey: Self.defaultsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        isLoading = true
        theme = snapshot.theme
        editorFontFamily = snapshot.editorFontFamily
        editorFontSize = snapshot.editorFontSize
        editorLineHeight = snapshot.editorLineHeight
        intelligenceURLString = Self.migratedURL(snapshot.intelligenceURLString, isDebug: Self.isDebugBuild)
        proseHighlightsEnabled = snapshot.proseHighlightsEnabled ?? false
        visibleAnalysisTypes = snapshot.visibleAnalysisTypes ?? []
        spellcheckEnabled = snapshot.spellcheckEnabled ?? true
        exportDefaults = snapshot.exportDefaults
        upsellDismissed = snapshot.upsellDismissed ?? false
        dimsParagraphsInFocusMode = snapshot.dimsParagraphsInFocusMode ?? true
        isLoading = false

        // Builds before the Keychain kept the key in the blob: move it over
        // (unless the Keychain already has one) and rewrite the blob without it.
        if let legacyKey = snapshot.licenseKey {
            if licenseKey.isEmpty, !legacyKey.isEmpty {
                licenseKey = legacyKey
            }
            persist()
        }
    }

    private func persist() {
        guard !isLoading else { return }
        let snapshot = Snapshot(
            theme: theme,
            editorFontFamily: editorFontFamily,
            editorFontSize: editorFontSize,
            editorLineHeight: editorLineHeight,
            intelligenceURLString: intelligenceURLString,
            proseHighlightsEnabled: proseHighlightsEnabled,
            visibleAnalysisTypes: visibleAnalysisTypes,
            spellcheckEnabled: spellcheckEnabled,
            exportDefaults: exportDefaults,
            upsellDismissed: upsellDismissed,
            dimsParagraphsInFocusMode: dimsParagraphsInFocusMode
        )
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }
}
