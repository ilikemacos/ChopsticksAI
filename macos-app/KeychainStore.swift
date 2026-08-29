import Foundation

/// App-local secrets. UserDefaults only — never Keychain (unsigned builds prompt).
enum KeychainStore {
    private static let prefix = "chopsticksAI.secret."

    static func read(account: String) -> Data? {
        UserDefaults.standard.data(forKey: prefix + account)
    }

    static func write(account: String, data: Data) {
        UserDefaults.standard.set(data, forKey: prefix + account)
    }

    static func delete(account: String) {
        UserDefaults.standard.removeObject(forKey: prefix + account)
    }
}
