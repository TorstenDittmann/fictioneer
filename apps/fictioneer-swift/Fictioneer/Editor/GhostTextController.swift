import Foundation

/// What the editor should render for the ghost suggestion.
struct GhostDisplay: Equatable {
    var text: String
    var showsAcceptHint: Bool
    var alpha: Double
}

/// The ghost-text state machine. Pure logic — no AppKit — so the full
/// ⌥-hold → stream → accept/dismiss matrix is unit-testable.
///
///     idle → waiting(dots) → streaming(text) → ready(text) → idle (Tab accept)
///                    └────────────┴────────────────┴→ fadingOut → idle (⌥ release)
@Observable
final class GhostTextController {
    enum State: Equatable {
        case idle
        case waiting(dots: Int)
        case streaming(String)
        case ready(String)
        case fadingOut(String)
    }

    /// Returns a stream of the *accumulated* suggestion text for a request.
    typealias SuggestionProvider = @MainActor (
        _ content: String,
        _ context: IntelligenceClient.ContinueContext
    ) -> AsyncThrowingStream<String, Error>

    private(set) var state: State = .idle
    @ObservationIgnored var onDisplayChange: ((GhostDisplay?) -> Void)?

    private let provider: SuggestionProvider
    private let minContextLength: Int
    private let dotsInterval: TimeInterval
    private let fadeDuration: TimeInterval
    private var streamTask: Task<Void, Never>?
    private var dotsTask: Task<Void, Never>?
    private var fadeTask: Task<Void, Never>?

    init(
        minContextLength: Int = AppConfig.ghostTextMinContextLength,
        dotsInterval: TimeInterval = 0.15,
        fadeDuration: TimeInterval = 0.2,
        provider: @escaping SuggestionProvider
    ) {
        self.minContextLength = minContextLength
        self.dotsInterval = dotsInterval
        self.fadeDuration = fadeDuration
        self.provider = provider
    }

    var isActive: Bool {
        state != .idle
    }

    // MARK: - Inputs

    func optionKeyDown(
        contextText: String,
        context: IntelligenceClient.ContinueContext,
        selectionEmpty: Bool
    ) {
        // Never concurrent — and deliberately ignored during .fadingOut: the
        // presenter refuses re-entry while a ghost is still active, so a
        // re-press during the fade simply waits for idle.
        guard case .idle = state else { return }
        guard selectionEmpty, contextText.count >= minContextLength else { return }
        state = .waiting(dots: 1)
        emit()
        startDotsAnimation()
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await accumulated in provider(contextText, context) {
                    guard !Task.isCancelled else { return }
                    streamDidYield(accumulated)
                }
                guard !Task.isCancelled else { return }
                streamDidFinish()
            } catch {
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
    }

    func optionKeyUp() {
        switch state {
        case .idle, .fadingOut:
            return
        case .waiting, .streaming, .ready:
            let text = currentText
            cancelWork()
            state = .fadingOut(text)
            emit()
            fadeTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(self?.fadeDuration ?? 0.2))
                guard let self, !Task.isCancelled, case .fadingOut = state else { return }
                state = .idle
                emit()
            }
        }
    }

    /// Returns the suggestion to insert when a complete suggestion is showing.
    func tabPressed() -> String? {
        guard case .ready(let text) = state else { return nil }
        cancelWork()
        state = .idle
        emit()
        return text
    }

    /// Returns true when the key event was consumed (a ghost was dismissed).
    @discardableResult
    func escapePressed() -> Bool {
        guard isActive else { return false }
        dismiss()
        return true
    }

    func documentDidChange() {
        guard isActive else { return }
        dismiss()
    }

    // MARK: - Stream events

    private func streamDidYield(_ accumulated: String) {
        switch state {
        case .waiting, .streaming:
            dotsTask?.cancel()
            state = .streaming(accumulated)
            emit()
        case .idle, .ready, .fadingOut:
            break
        }
    }

    private func streamDidFinish() {
        guard case .streaming(let text) = state else {
            dismiss()
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            dismiss()
        } else {
            state = .ready(trimmed)
            emit()
        }
    }

    // MARK: - Helpers

    private var currentText: String {
        switch state {
        case .waiting(let dots): String(repeating: ".", count: dots)
        case .streaming(let text), .ready(let text), .fadingOut(let text): text
        case .idle: ""
        }
    }

    private func startDotsAnimation() {
        dotsTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.dotsInterval ?? 0.15))
                guard let self, !Task.isCancelled, case .waiting(let dots) = state else { return }
                state = .waiting(dots: dots % 3 + 1)
                emit()
            }
        }
    }

    private func dismiss() {
        cancelWork()
        fadeTask?.cancel()
        state = .idle
        emit()
    }

    private func cancelWork() {
        streamTask?.cancel()
        streamTask = nil
        dotsTask?.cancel()
        dotsTask = nil
    }

    private func emit() {
        let display: GhostDisplay? = switch state {
        case .idle:
            nil
        case .waiting(let dots):
            GhostDisplay(text: String(repeating: ".", count: dots), showsAcceptHint: false, alpha: 0.8)
        case .streaming(let text):
            GhostDisplay(text: text, showsAcceptHint: false, alpha: 1)
        case .ready(let text):
            GhostDisplay(text: text, showsAcceptHint: true, alpha: 1)
        case .fadingOut(let text):
            GhostDisplay(text: text, showsAcceptHint: false, alpha: 0.35)
        }
        onDisplayChange?(display)
    }
}
