import Foundation
import Security

/// Storage for secrets that must not live in plaintext preferences.
protocol SecretStore: AnyObject {
    func string(forKey key: String) -> String?
    /// An empty value removes the secret.
    func set(_ value: String, forKey key: String)
}

/// Generic-password items in the user's login keychain, scoped to the app.
final class KeychainSecretStore: SecretStore {
    private let service: String

    init(service: String = "app.fictioneer") {
        self.service = service
    }

    func string(forKey key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func set(_ value: String, forKey key: String) {
        let query = baseQuery(for: key)
        guard !value.isEmpty else {
            SecItemDelete(query as CFDictionary)
            return
        }
        let data = Data(value.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}

/// For tests and previews.
final class InMemorySecretStore: SecretStore {
    private var values: [String: String] = [:]

    func string(forKey key: String) -> String? { values[key] }

    func set(_ value: String, forKey key: String) {
        values[key] = value.isEmpty ? nil : value
    }
}
