import Foundation

enum AppConfig {
    // TODO: fill in the production intelligence server URL before shipping.
    // The value is not stored in the repo (it lives in a GitHub Actions variable);
    // it can also be overridden per-user in Settings, matching the Tauri app.
    static let defaultIntelligenceBaseURL = "http://localhost:3001"

    static let projectFileExtension = "fictioneer"
    static let formatVersion = 1

    static let autosaveDebounce: TimeInterval = 3.0
    static let autosaveThrottle: TimeInterval = 5.0
    static let maxRecentProjects = 10

    static let ghostTextWordCount = 36
    static let ghostTextContextWindow = 2000
    static let ghostTextMinContextLength = 10
}
