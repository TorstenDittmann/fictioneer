import Foundation

@Observable
final class LicenseManager {
    enum Status: Equatable {
        case unknown
        case verifying
        case valid
        case invalid
        case error(String)
    }

    private(set) var status: Status = .unknown
    private var verifyTask: Task<Void, Never>?

    var isReadyForSuggestions: Bool {
        status == .valid
    }

    func verify(key: String, baseURL: URL) {
        verifyTask?.cancel()
        guard !key.trimmingCharacters(in: .whitespaces).isEmpty else {
            status = .unknown
            return
        }
        status = .verifying
        let client = IntelligenceClient(baseURL: baseURL, licenseKey: key)
        verifyTask = Task { [weak self] in
            do {
                try await client.verify()
                guard !Task.isCancelled else { return }
                self?.status = .valid
            } catch IntelligenceError.invalidLicense {
                guard !Task.isCancelled else { return }
                self?.status = .invalid
            } catch {
                guard !Task.isCancelled else { return }
                self?.status = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        verifyTask?.cancel()
        status = .unknown
    }
}
