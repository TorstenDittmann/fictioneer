import Foundation
import SwiftUI

/// Persisted export sheet preferences (include-toggles, format, EPUB
/// template). Per-project book metadata (author, publisher, ...) is not
/// part of this — it lives on the project itself.
nonisolated struct ExportDefaults: Codable, Equatable {
    var format: ExportFormat
    var includeTitle: Bool
    var includeChapterTitles: Bool
    var includeSceneTitles: Bool
    var includeWordCount: Bool
    var epubTemplate: EpubTemplate
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
    var licenseKey: String = "" { didSet { persist() } }
    /// Prose-analysis inline highlights (off by default, matching the Tauri app).
    var proseHighlightsEnabled: Bool = false { didSet { persist() } }
    /// Raw values of visible AnalysisType cases; empty means "all".
    var visibleAnalysisTypes: [String] = [] { didSet { persist() } }
    var spellcheckEnabled: Bool = true { didSet { persist() } }
    var exportDefaults: ExportDefaults? { didSet { persist() } }
    /// Set once the welcome-screen license upsell card is dismissed; the card never returns.
    var upsellDismissed: Bool = false { didSet { persist() } }

    private nonisolated struct Snapshot: Codable {
        var theme: Theme
        var editorFontFamily: String
        var editorFontSize: Double
        var editorLineHeight: Double
        var intelligenceURLString: String
        var licenseKey: String
        var proseHighlightsEnabled: Bool?
        var visibleAnalysisTypes: [String]?
        var spellcheckEnabled: Bool?
        var exportDefaults: ExportDefaults?
        var upsellDismissed: Bool?

        init(
            theme: Theme,
            editorFontFamily: String,
            editorFontSize: Double,
            editorLineHeight: Double,
            intelligenceURLString: String,
            licenseKey: String,
            proseHighlightsEnabled: Bool?,
            visibleAnalysisTypes: [String]?,
            spellcheckEnabled: Bool?,
            exportDefaults: ExportDefaults?,
            upsellDismissed: Bool?
        ) {
            self.theme = theme
            self.editorFontFamily = editorFontFamily
            self.editorFontSize = editorFontSize
            self.editorLineHeight = editorLineHeight
            self.intelligenceURLString = intelligenceURLString
            self.licenseKey = licenseKey
            self.proseHighlightsEnabled = proseHighlightsEnabled
            self.visibleAnalysisTypes = visibleAnalysisTypes
            self.spellcheckEnabled = spellcheckEnabled
            self.exportDefaults = exportDefaults
            self.upsellDismissed = upsellDismissed
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            theme = try container.decode(Theme.self, forKey: .theme)
            editorFontFamily = try container.decode(String.self, forKey: .editorFontFamily)
            editorFontSize = try container.decode(Double.self, forKey: .editorFontSize)
            editorLineHeight = try container.decode(Double.self, forKey: .editorLineHeight)
            intelligenceURLString = try container.decode(String.self, forKey: .intelligenceURLString)
            licenseKey = try container.decode(String.self, forKey: .licenseKey)
            proseHighlightsEnabled = try container.decodeIfPresent(Bool.self, forKey: .proseHighlightsEnabled)
            visibleAnalysisTypes = try container.decodeIfPresent([String].self, forKey: .visibleAnalysisTypes)
            spellcheckEnabled = try container.decodeIfPresent(Bool.self, forKey: .spellcheckEnabled)
            // Deliberately lenient: ExportDefaults nests non-optional enums,
            // so an unknown rawValue written by a future version must degrade
            // to nil — not fail the whole snapshot and wipe every setting
            // (including the license key).
            exportDefaults = try? container.decodeIfPresent(ExportDefaults.self, forKey: .exportDefaults)
            upsellDismissed = try container.decodeIfPresent(Bool.self, forKey: .upsellDismissed)
        }
    }

    private static let defaultsKey = "fictioneer.settings"
    private let defaults: UserDefaults
    private var isLoading = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
        guard let data = defaults.data(forKey: Self.defaultsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        isLoading = true
        theme = snapshot.theme
        editorFontFamily = snapshot.editorFontFamily
        editorFontSize = snapshot.editorFontSize
        editorLineHeight = snapshot.editorLineHeight
        intelligenceURLString = Self.migratedURL(snapshot.intelligenceURLString, isDebug: Self.isDebugBuild)
        licenseKey = snapshot.licenseKey
        proseHighlightsEnabled = snapshot.proseHighlightsEnabled ?? false
        visibleAnalysisTypes = snapshot.visibleAnalysisTypes ?? []
        spellcheckEnabled = snapshot.spellcheckEnabled ?? true
        exportDefaults = snapshot.exportDefaults
        upsellDismissed = snapshot.upsellDismissed ?? false
        isLoading = false
    }

    private func persist() {
        guard !isLoading else { return }
        let snapshot = Snapshot(
            theme: theme,
            editorFontFamily: editorFontFamily,
            editorFontSize: editorFontSize,
            editorLineHeight: editorLineHeight,
            intelligenceURLString: intelligenceURLString,
            licenseKey: licenseKey,
            proseHighlightsEnabled: proseHighlightsEnabled,
            visibleAnalysisTypes: visibleAnalysisTypes,
            spellcheckEnabled: spellcheckEnabled,
            exportDefaults: exportDefaults,
            upsellDismissed: upsellDismissed
        )
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }
}
