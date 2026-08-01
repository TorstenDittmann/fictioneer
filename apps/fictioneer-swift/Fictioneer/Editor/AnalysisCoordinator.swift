import Foundation

/// Runs the analysis engine off the typing path (300ms debounce, content-hash
/// short-circuit, detached computation) and hands display work to the
/// highlighter. Application is refused when the content changed since the
/// analysis snapshot or while a ghost suggestion is inserted.
@Observable
final class AnalysisCoordinator {
    private(set) var result: AnalysisResult?
    private(set) var isAnalyzing = false

    @ObservationIgnored private weak var editorController: EditorController?
    @ObservationIgnored private weak var settings: AppSettings?
    @ObservationIgnored private var highlighter: AnalysisHighlighter?
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var lastAnalyzedHash: Int?

    func attach(editorController: EditorController, settings: AppSettings) {
        self.editorController = editorController
        self.settings = settings
        highlighter = AnalysisHighlighter(editorController: editorController)
        if let text = currentPlainText() {
            contentDidChange(text)
        }
    }

    func contentDidChange(_ plainText: String) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.analyze(plainText)
        }
    }

    func setHighlightsEnabled(_ enabled: Bool) {
        settings?.proseHighlightsEnabled = enabled
        if enabled {
            applyIfPossible()
        } else {
            highlighter?.clear()
        }
    }

    var highlightsEnabled: Bool {
        settings?.proseHighlightsEnabled ?? false
    }

    private func analyze(_ text: String) async {
        let hash = TextAnalysisEngine.contentHash(text)
        if hash == lastAnalyzedHash, result != nil {
            applyIfPossible()
            return
        }
        isAnalyzing = true
        let computed = await Task.detached(priority: .utility) {
            TextAnalysisEngine.analyze(text)
        }.value
        isAnalyzing = false
        lastAnalyzedHash = hash
        result = computed
        applyIfPossible()
    }

    private func applyIfPossible() {
        guard let settings, settings.proseHighlightsEnabled,
              let result,
              let editorController,
              !editorController.isGhostActive,
              let current = currentPlainText(),
              TextAnalysisEngine.contentHash(current) == result.contentHash
        else { return }
        let visibleRaw = settings.visibleAnalysisTypes
        let visible = visibleRaw.isEmpty
            ? nil
            : Set(visibleRaw.compactMap(AnalysisType.init(rawValue:)))
        highlighter?.apply(result.highlights, visibleTypes: visible)
    }

    private func currentPlainText() -> String? {
        editorController?.textView?.attributedString().strippingTransientAttributes().string
    }
}
