import Foundation

nonisolated enum IntelligenceError: Error, LocalizedError, Equatable {
    case invalidLicense
    case rateLimited
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .invalidLicense: "The license key is invalid."
        case .rateLimited: "Too many requests — try again in a moment."
        case .server(let code): "The AI service returned an error (\(code))."
        }
    }

    static func from(statusCode: Int) -> IntelligenceError {
        switch statusCode {
        case 401, 403: .invalidLicense
        case 429: .rateLimited
        default: .server(statusCode)
        }
    }
}

/// Client for the existing `apps/intelligence` backend.
nonisolated struct IntelligenceClient: Sendable {
    struct ContinueContext: Encodable, Sendable {
        var title: String?
        var sceneDescription: String?
        var recentText: String?
        var instruction: String?

        enum CodingKeys: String, CodingKey {
            case title
            case sceneDescription = "scene_description"
            case recentText = "recent_text"
            case instruction
        }
    }

    var baseURL: URL
    var licenseKey: String
    var urlSession: URLSession = .shared

    /// `POST /api/verify` — throws IntelligenceError on 401/429/5xx.
    func verify() async throws {
        var request = makeRequest(path: "api/verify")
        request.httpBody = Data("{}".utf8)
        let (_, response) = try await urlSession.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw IntelligenceError.from(statusCode: status)
        }
    }

    /// `POST /api/continue` with the exact `accept: text/plain+stream` header the
    /// backend requires for streaming. Yields the *accumulated* suggestion text.
    /// Cancel by cancelling the consuming task.
    func continueWriting(
        content: String,
        context: ContinueContext,
        wordCount: Int = AppConfig.ghostTextWordCount
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = makeRequest(path: "api/continue")
                    request.setValue("text/plain+stream", forHTTPHeaderField: "Accept")
                    struct Body: Encodable {
                        let content: String
                        let context: ContinueContext
                        let word_count: Int
                    }
                    request.httpBody = try JSONEncoder().encode(
                        Body(content: content, context: context, word_count: wordCount)
                    )

                    let (bytes, response) = try await urlSession.bytes(for: request)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    guard status == 200 else {
                        throw IntelligenceError.from(statusCode: status)
                    }

                    var accumulated = ""
                    var pending: [UInt8] = []
                    for try await byte in bytes {
                        pending.append(byte)
                        // Decode only complete UTF-8 sequences; partial multibyte
                        // characters stay pending until their continuation bytes arrive.
                        if let decoded = String(bytes: pending, encoding: .utf8) {
                            pending.removeAll(keepingCapacity: true)
                            accumulated += decoded
                            continuation.yield(accumulated)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func makeRequest(path: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("Bearer \(licenseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
