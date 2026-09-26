import Foundation

/// Runs the analysis engine off the typing path (300ms debounce, content-hash
/// short-circuit, detached computation) and hands display work to the
/// highlighter. Application is refused when the content changed since the
/// analysis snapshot or while a ghost suggestion is inserted.
@Observable
final class AnalysisCoordinator {
    private(set) var result: AnalysisResult?
    private(set) var isAnalyzing = false

    /// Ids of project notes whose tags appear in the current scene text —
    /// recomputed on the same debounce cadence as `result` (piggybacked, not
    /// a separate timer). Populated by the caller-supplied candidates, so
    /// this layer never depends on the `Note` model or persistence.
    private(set) var matchingNoteIDs: [UUID] = []

    @ObservationIgnored private weak var editorController: EditorController?
    @ObservationIgnored private weak var settings: AppSettings?
    @ObservationIgnored private var highlighter: AnalysisHighlighter?
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var lastAnalyzedHash: Int?
    /// Monotonic token: an analysis run only publishes its result if no newer
    /// run started while it was computing (older runs can finish later and
    /// would otherwise clobber `result` / `lastAnalyzedHash` / `isAnalyzing`).
    @ObservationIgnored private var generation = 0

    func attach(editorController: EditorController, settings: AppSettings, noteCandidates: [NoteMatcher.Candidate] = []) {
        self.editorController = editorController
        self.settings = settings
        highlighter = AnalysisHighlighter(editorController: editorController)
        if let text = currentPlainText() {
            contentDidChange(text, noteCandidates: noteCandidates)
        }
    }

    func contentDidChange(_ plainText: String, noteCandidates: [NoteMatcher.Candidate] = []) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.analyze(plainText, noteCandidates: noteCandidates)
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

    private func analyze(_ text: String, noteCandidates: [NoteMatcher.Candidate]) async {
        generation += 1
        let myGeneration = generation

        let hash = TextAnalysisEngine.contentHash(text)
        if hash == lastAnalyzedHash, result != nil {
            matchingNoteIDs = NoteMatcher.matchingIDs(in: text, notes: noteCandidates)
            applyIfPossible()
            return
        }
        isAnalyzing = true
        let computed = await Task.detached(priority: .utility) {
            TextAnalysisEngine.analyze(text)
        }.value
        // A newer run started while this one computed: its result is the one
        // that matches the editor, so this run must not touch any state.
        guard generation == myGeneration else { return }
        isAnalyzing = false
        lastAnalyzedHash = hash
        result = computed
        matchingNoteIDs = NoteMatcher.matchingIDs(in: text, notes: noteCandidates)
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
