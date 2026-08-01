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
    }

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

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: script.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in script.chunks {
            if script.chunkDelay > 0 {
                Thread.sleep(forTimeInterval: script.chunkDelay)
            }
            client?.urlProtocol(self, didLoad: chunk)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

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
        StubURLProtocol.script = .init(statusCode: 200, chunks: chunks, chunkDelay: 0.1)
        let client = makeClient()

        let consumer = Task {
            var last = ""
            do {
                for try await accumulated in client.continueWriting(content: "0123456789", context: .init()) {
                    last = accumulated
                }
            } catch {}
            return last
        }
        try await Task.sleep(for: .milliseconds(350))
        consumer.cancel()
        let received = await consumer.value
        #expect(!received.isEmpty)
        #expect(received.utf8.count < totalBytes)
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
}
