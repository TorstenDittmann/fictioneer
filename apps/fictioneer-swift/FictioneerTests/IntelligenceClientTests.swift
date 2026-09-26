import Foundation
import Testing
@testable import Fictioneer

/// URLProtocol stub that replays a scripted response, delivering body chunks
/// incrementally so the streaming path is exercised for real.
nonisolated final class StubURLProtocol: URLProtocol {
    struct Script: @unchecked Sendable {
        var statusCode: Int
        var chunks: [Data]
        var chunkDelay: TimeInterval = 0
        /// Transport-level failure delivered instead of any response.
        var error: Error?
    }

    /// Set by `stopLoading` (client thread) and checked by the delayed chunk
    /// loop (background thread) so cancellation actually stops delivery.
    private final class StopFlag: @unchecked Sendable {
        private let lock = NSLock()
        private var _stopped = false

        var stopped: Bool {
            get {
                lock.lock()
                defer { lock.unlock() }
                return _stopped
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                _stopped = newValue
            }
        }
    }

    private let stopFlag = StopFlag()

    final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var _requests: [URLRequest] = []
        private var _bodies: [Data] = []

        func record(_ request: URLRequest, body: Data) {
            lock.lock()
            defer { lock.unlock() }
            _requests.append(request)
            _bodies.append(body)
        }

        var requests: [URLRequest] {
            lock.lock()
            defer { lock.unlock() }
            return _requests
        }

        var bodies: [Data] {
            lock.lock()
            defer { lock.unlock() }
            return _bodies
        }
    }

    nonisolated(unsafe) static var script = Script(statusCode: 200, chunks: [])
    nonisolated(unsafe) static var recorder = Recorder()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let script = Self.script
        Self.recorder.record(request, body: Self.drainBody(of: request))

        if let error = script.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: script.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        guard script.chunkDelay > 0 else {
            for chunk in script.chunks {
                client?.urlProtocol(self, didLoad: chunk)
            }
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // Delayed delivery happens off the protocol's thread so stopLoading
        // can interleave; the loop re-checks the stop flag around each sleep,
        // so a cancelled load neither delivers more data nor leaks a thread
        // sleeping through the rest of the script.
        nonisolated(unsafe) let stub = self
        DispatchQueue.global().async {
            for chunk in script.chunks {
                if stub.stopFlag.stopped { return }
                Thread.sleep(forTimeInterval: script.chunkDelay)
                if stub.stopFlag.stopped { return }
                stub.client?.urlProtocol(stub, didLoad: chunk)
            }
            if !stub.stopFlag.stopped {
                stub.client?.urlProtocolDidFinishLoading(stub)
            }
        }
    }

    override func stopLoading() {
        stopFlag.stopped = true
    }

    private static func drainBody(of request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

// Serialized: the URLProtocol stub's script/recorder are process-global.
@Suite(.serialized)
@MainActor
struct IntelligenceClientTests {
    private func makeClient() -> IntelligenceClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        StubURLProtocol.recorder = StubURLProtocol.Recorder()
        return IntelligenceClient(
            baseURL: URL(string: "https://stub.test")!,
            licenseKey: "test-key-123",
            urlSession: URLSession(configuration: configuration)
        )
    }

    @Test func continueStreamsAccumulatedText() async throws {
        StubURLProtocol.script = .init(statusCode: 200, chunks: [
            Data(" the storm".utf8),
            Data(" rolled in".utf8),
            Data(" from the sea.".utf8),
        ])
        let client = makeClient()

        var yields: [String] = []
        for try await accumulated in client.continueWriting(
            content: "It was a dark night and",
            context: .init(title: "Opening"),
            wordCount: 36
        ) {
            yields.append(accumulated)
        }

        #expect(yields.last == " the storm rolled in from the sea.")
        #expect(!yields.isEmpty)

        // Contract assertions: exact streaming header, bearer auth, JSON body.
        let request = try #require(StubURLProtocol.recorder.requests.first)
        #expect(request.url?.path == "/api/continue")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/plain+stream")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key-123")
        let body = try #require(StubURLProtocol.recorder.bodies.first)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["content"] as? String == "It was a dark night and")
        #expect(json["word_count"] as? Int == 36)
        #expect((json["context"] as? [String: Any])?["title"] as? String == "Opening")
    }

    @Test func multibyteCharactersSplitAcrossChunksDecodeCleanly() async throws {
        let ellipsis = Data("…".utf8) // 3 bytes
        StubURLProtocol.script = .init(statusCode: 200, chunks: [
            Data("wait".utf8) + ellipsis.prefix(1),
            ellipsis.suffix(2) + Data(" done".utf8),
        ])
        let client = makeClient()

        var last = ""
        for try await accumulated in client.continueWriting(content: "0123456789", context: .init()) {
            last = accumulated
        }
        #expect(last == "wait… done")
    }

    @Test func unauthorizedThrowsInvalidLicense() async {
        StubURLProtocol.script = .init(statusCode: 401, chunks: [])
        let client = makeClient()

        await #expect(throws: IntelligenceError.invalidLicense) {
            for try await _ in client.continueWriting(content: "0123456789", context: .init()) {}
        }
    }

    @Test func cancellationStopsConsumption() async throws {
        // Large chunks defeat CFNetwork's small-payload buffering so data
        // actually streams to the consumer before the cancellation point.
        let chunks = (0..<20).map { _ in Data(String(repeating: "x", count: 1024).utf8) }
        let totalBytes = chunks.reduce(0) { $0 + $1.count }
        StubURLProtocol.script = .init(statusCode: 200, chunks: chunks, chunkDelay: 0.05)
        let client = makeClient()

        // Cancellation is driven off the first observed value — no fixed
        // sleeps racing the delivery cadence.
        let (firstValue, firstValueContinuation) = AsyncStream.makeStream(of: Void.self)
        let consumer = Task {
            var last = ""
            do {
                for try await accumulated in client.continueWriting(content: "0123456789", context: .init()) {
                    if last.isEmpty { firstValueContinuation.yield() }
                    last = accumulated
                }
            } catch {}
            return last
        }
        var iterator = firstValue.makeAsyncIterator()
        _ = await iterator.next()
        consumer.cancel()
        let received = await consumer.value
        #expect(!received.isEmpty)
        #expect(received.utf8.count < totalBytes)
    }

    @Test(arguments: [
        (401, IntelligenceError.invalidLicense),
        (403, IntelligenceError.invalidLicense),
        (429, IntelligenceError.rateLimited),
        (500, IntelligenceError.server(500)),
    ])
    func streamingSurfacesMappedStatusErrors(status: Int, expected: IntelligenceError) async {
        StubURLProtocol.script = .init(statusCode: status, chunks: [])
        let client = makeClient()
        await #expect(throws: expected) {
            for try await _ in client.continueWriting(content: "0123456789", context: .init()) {}
        }
    }

    @Test func verifyThrowsServerErrorOn500() async {
        StubURLProtocol.script = .init(statusCode: 500, chunks: [])
        await #expect(throws: IntelligenceError.server(500)) {
            try await makeClient().verify()
        }
    }

    @Test func rephraseThrowsOnMalformedJSON() async {
        StubURLProtocol.script = .init(statusCode: 200, chunks: [Data("{not json at all".utf8)])
        await #expect(throws: DecodingError.self) {
            _ = try await makeClient().rephrase(
                selectedSentence: "She was sad.", contextBefore: "", contextAfter: ""
            )
        }
    }

    @Test func transportFailureSurfacesFromStream() async {
        StubURLProtocol.script = .init(
            statusCode: 200, chunks: [],
            error: URLError(.notConnectedToInternet)
        )
        let client = makeClient()
        await #expect(throws: URLError.self) {
            for try await _ in client.continueWriting(content: "0123456789", context: .init()) {}
        }
    }

    @Test func verifySucceedsOn200() async throws {
        StubURLProtocol.script = .init(statusCode: 200, chunks: [Data("OK".utf8)])
        try await makeClient().verify()
        let request = try #require(StubURLProtocol.recorder.requests.first)
        #expect(request.url?.path == "/api/verify")
    }

    @Test func verifyThrowsOnRateLimit() async {
        StubURLProtocol.script = .init(statusCode: 429, chunks: [])
        await #expect(throws: IntelligenceError.rateLimited) {
            try await makeClient().verify()
        }
    }

    @Test func rephraseDecodesTypedAlternatives() async throws {
        let json = """
        {"original": "She was sad.", "rephrases": [
            {"type": "vivid", "alternative": "Grief pressed her shoulders down."},
            {"type": "tighter", "alternative": "She grieved."},
            {"type": "show_dont_tell", "alternative": "She stared at the empty chair."},
            {"type": "change_pov", "alternative": "I watched her sadness surface."},
            {"type": "simplify", "alternative": "She felt sad."}
        ]}
        """
        StubURLProtocol.script = .init(statusCode: 200, chunks: [Data(json.utf8)])
        let response = try await makeClient().rephrase(
            selectedSentence: "She was sad.", contextBefore: "before", contextAfter: "after"
        )
        #expect(response.original == "She was sad.")
        #expect(response.rephrases.count == 5)
        #expect(response.rephrases.map(\.type) == ["vivid", "tighter", "show_dont_tell", "change_pov", "simplify"])

        let request = try #require(StubURLProtocol.recorder.requests.first)
        #expect(request.url?.path == "/api/rephrase")
        let body = try #require(StubURLProtocol.recorder.bodies.first)
        let parsed = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(parsed["selected_sentence"] as? String == "She was sad.")
        #expect(parsed["context_before"] as? String == "before")
    }

    @Test func startStreamsWithExactHeaderAndBody() async throws {
        StubURLProtocol.script = .init(statusCode: 200, chunks: [Data("Once upon".utf8), Data(" a time".utf8)])
        var last = ""
        for try await accumulated in makeClient().start(prompt: "Begin a fairy tale", wordCount: 150) {
            last = accumulated
        }
        #expect(last == "Once upon a time")

        let request = try #require(StubURLProtocol.recorder.requests.first)
        #expect(request.url?.path == "/api/start")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/plain+stream")
        let body = try #require(StubURLProtocol.recorder.bodies.first)
        let parsed = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(parsed["prompt"] as? String == "Begin a fairy tale")
        #expect(parsed["word_count"] as? Int == 150)
    }
}
