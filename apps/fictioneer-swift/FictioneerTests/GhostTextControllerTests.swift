import Foundation
import Testing
@testable import Fictioneer

/// Drives the controller through a hand-controlled suggestion stream.
@MainActor
private final class Harness {
    /// Written from `onTermination` (arbitrary thread), read from MainActor —
    /// locked like StubURLProtocol.Recorder.
    nonisolated final class Flags: @unchecked Sendable {
        private let lock = NSLock()
        private var _terminated = false

        var terminated: Bool {
            get {
                lock.lock()
                defer { lock.unlock() }
                return _terminated
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                _terminated = newValue
            }
        }
    }

    @MainActor
    final class StreamBox {
        let flags = Flags()
        var continuation: AsyncThrowingStream<String, Error>.Continuation?
        var providerCalls = 0
    }

    let controller: GhostTextController
    private let box = StreamBox()
    var displays: [GhostDisplay?] = []

    var continuation: AsyncThrowingStream<String, Error>.Continuation? { box.continuation }
    var providerCalls: Int { box.providerCalls }
    var flags: Flags { box.flags }

    init() {
        let box = box
        controller = GhostTextController(
            dotsInterval: 0.01,
            fadeDuration: 0.02
        ) { _, _ in
            box.providerCalls += 1
            return AsyncThrowingStream { continuation in
                let flags = box.flags
                continuation.onTermination = { reason in
                    if case .cancelled = reason {
                        flags.terminated = true
                    }
                }
                Task { @MainActor in
                    box.continuation = continuation
                }
            }
        }
        controller.onDisplayChange = { [weak self] display in
            self?.displays.append(display)
        }
    }

    func holdOption(context: String = "It was a dark and stormy night") {
        controller.optionKeyDown(
            contextText: context,
            context: .init(),
            selectionEmpty: true
        )
    }

    func waitUntil(
        timeoutMilliseconds: Int = 2000,
        _ condition: () -> Bool
    ) async {
        for _ in 0..<(timeoutMilliseconds / 5) {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(5))
        }
        Issue.record("Timed out waiting for condition")
    }

    func waitForStreamStart() async {
        await waitUntil { continuation != nil }
    }
}

@MainActor
struct GhostTextControllerTests {
    @Test func shortContextStaysIdle() async {
        let harness = Harness()
        harness.holdOption(context: "short")
        #expect(harness.controller.state == .idle)
        try? await Task.sleep(for: .milliseconds(20))
        #expect(harness.providerCalls == 0)
    }

    @Test func nonEmptySelectionStaysIdle() {
        let harness = Harness()
        harness.controller.optionKeyDown(
            contextText: "long enough context here",
            context: .init(),
            selectionEmpty: false
        )
        #expect(harness.controller.state == .idle)
    }

    @Test func fullFlowStreamsAndAcceptsWithTab() async {
        let harness = Harness()
        harness.holdOption()
        #expect(harness.controller.state == .waiting(dots: 1))

        await harness.waitForStreamStart()
        harness.continuation?.yield(" the wind")
        await harness.waitUntil { harness.controller.state == .streaming(" the wind") }

        harness.continuation?.yield(" the wind howled.")
        await harness.waitUntil { harness.controller.state == .streaming(" the wind howled.") }

        harness.continuation?.finish()
        await harness.waitUntil { harness.controller.state == .ready("the wind howled.") }
        #expect(harness.displays.last??.showsAcceptHint == true)

        let accepted = harness.controller.tabPressed()
        #expect(accepted == "the wind howled.")
        #expect(harness.controller.state == .idle)
        #expect(harness.displays.last! == nil)
    }

    @Test func tabDoesNothingWhileStreaming() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("partial")
        await harness.waitUntil { harness.controller.state == .streaming("partial") }
        #expect(harness.controller.tabPressed() == nil)
        #expect(harness.controller.state == .streaming("partial"))
    }

    @Test func optionReleaseMidStreamFadesThenCancels() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("some words")
        await harness.waitUntil { harness.controller.state == .streaming("some words") }

        harness.controller.optionKeyUp()
        #expect(harness.controller.state == .fadingOut("some words"))
        await harness.waitUntil { harness.controller.state == .idle }
        await harness.waitUntil { harness.flags.terminated }
        #expect(harness.displays.last! == nil)
    }

    @Test func documentEditDismissesImmediately() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("ghost")
        await harness.waitUntil { harness.controller.state == .streaming("ghost") }

        harness.controller.documentDidChange()
        #expect(harness.controller.state == .idle)
        await harness.waitUntil { harness.flags.terminated }
    }

    @Test func escapeDismissesWhenReady() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("done.")
        await harness.waitUntil { harness.controller.state == .streaming("done.") }
        harness.continuation?.finish()
        await harness.waitUntil { harness.controller.state == .ready("done.") }

        #expect(harness.controller.escapePressed() == true)
        #expect(harness.controller.state == .idle)
        #expect(harness.controller.escapePressed() == false)
    }

    @Test func optionReleaseWhileWaitingFadesDotsThenIdles() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        guard case .waiting = harness.controller.state else {
            Issue.record("expected .waiting, got \(harness.controller.state)")
            return
        }

        harness.controller.optionKeyUp()
        guard case .fadingOut = harness.controller.state else {
            Issue.record("expected .fadingOut, got \(harness.controller.state)")
            return
        }
        await harness.waitUntil { harness.controller.state == .idle }
        #expect(harness.displays.last! == nil)
        await harness.waitUntil { harness.flags.terminated }
    }

    @Test func optionReleaseWhenReadyDiscardsCompletedSuggestion() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("done.")
        await harness.waitUntil { harness.controller.state == .streaming("done.") }
        harness.continuation?.finish()
        await harness.waitUntil { harness.controller.state == .ready("done.") }

        harness.controller.optionKeyUp()
        #expect(harness.controller.state == .fadingOut("done."))
        // Nothing left to accept once release chose to discard.
        #expect(harness.controller.tabPressed() == nil)
        await harness.waitUntil { harness.controller.state == .idle }
        #expect(harness.displays.last! == nil)
    }

    @Test func escapeDismissesWhileWaiting() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()

        #expect(harness.controller.escapePressed() == true)
        #expect(harness.controller.state == .idle)
        #expect(harness.displays.last! == nil)
        await harness.waitUntil { harness.flags.terminated }
    }

    @Test func escapeDismissesWhileStreaming() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("half a tho")
        await harness.waitUntil { harness.controller.state == .streaming("half a tho") }

        #expect(harness.controller.escapePressed() == true)
        #expect(harness.controller.state == .idle)
        #expect(harness.displays.last! == nil)
        await harness.waitUntil { harness.flags.terminated }
    }

    @Test func lateYieldDuringFadeIsIgnored() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("some words")
        await harness.waitUntil { harness.controller.state == .streaming("some words") }

        harness.controller.optionKeyUp()
        #expect(harness.controller.state == .fadingOut("some words"))
        harness.continuation?.yield("some words arriving late")

        await harness.waitUntil { harness.controller.state == .idle }
        #expect(!harness.displays.contains { $0?.text.contains("late") == true })
    }

    /// Pins the chosen behavior: re-pressing ⌥ during the fade-out is
    /// ignored (the presenter refuses re-entry while a ghost is active) —
    /// no second request starts and the fade completes normally.
    @Test func rePressDuringFadeIsIgnored() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.yield("some words")
        await harness.waitUntil { harness.controller.state == .streaming("some words") }

        harness.controller.optionKeyUp()
        #expect(harness.controller.state == .fadingOut("some words"))
        harness.holdOption()
        #expect(harness.controller.state == .fadingOut("some words"))
        #expect(harness.providerCalls == 1)

        await harness.waitUntil { harness.controller.state == .idle }
        #expect(harness.providerCalls == 1)
    }

    @Test func neverRunsConcurrentRequests() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.holdOption()
        try? await Task.sleep(for: .milliseconds(20))
        #expect(harness.providerCalls == 1)
    }

    @Test func emptyResultDismisses() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.finish()
        await harness.waitUntil { harness.controller.state == .idle }
        #expect(harness.displays.last! == nil)
    }

    @Test func streamErrorDismisses() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitForStreamStart()
        harness.continuation?.finish(throwing: IntelligenceError.rateLimited)
        await harness.waitUntil { harness.controller.state == .idle }
    }

    @Test func waitingDotsAnimate() async {
        let harness = Harness()
        harness.holdOption()
        await harness.waitUntil {
            if case .waiting(let dots) = harness.controller.state, dots > 1 {
                return true
            }
            return false
        }
    }
}

@MainActor
struct GhostContextBuilderTests {
    @Test func midSentenceAsksForCompletion() {
        let context = GhostContextBuilder.build(
            contextText: "The detective walked into the",
            title: "Scene 1",
            sceneDescription: nil
        )
        #expect(context.instruction?.contains("incomplete sentence") == true)
        #expect(context.recentText == "The detective walked into the")
        #expect(context.title == "Scene 1")
    }

    @Test func sentenceBoundaryAsksForNewSentence() {
        let context = GhostContextBuilder.build(
            contextText: "It was over. The room fell silent.",
            title: nil,
            sceneDescription: nil
        )
        #expect(context.instruction?.contains("new sentence") == true)
        #expect(context.recentText == nil)
    }

    @Test func closingQuoteAfterTerminatorCountsAsBoundary() {
        let context = GhostContextBuilder.build(
            contextText: "\u{201C}Get out!\u{201D}",
            title: nil,
            sceneDescription: nil
        )
        #expect(context.instruction?.contains("new sentence") == true)
    }

    @Test func recentTextIsFragmentAfterLastTerminator() {
        let context = GhostContextBuilder.build(
            contextText: "He left. She stayed behind and",
            title: nil,
            sceneDescription: nil
        )
        #expect(context.recentText == "She stayed behind and")
    }
}
