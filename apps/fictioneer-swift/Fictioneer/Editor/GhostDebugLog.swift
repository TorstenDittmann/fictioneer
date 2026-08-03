import Foundation

/// Temporary diagnostic for the ghost-accept investigation. DEBUG-only; logs
/// to the sandbox tmp directory. Remove once the live-app issue is pinned.
enum GhostDebugLog {
    static func append(_ message: String) {
        #if DEBUG
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ghost.log")
        let line = "\(Date().timeIntervalSince1970) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
        #endif
    }
}
