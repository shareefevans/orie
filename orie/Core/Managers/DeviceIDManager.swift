//
//  DeviceIDManager.swift
//  orie
//

import Foundation
import Security

enum DeviceIDManager {
    private static let service = "com.orie.app"
    private static let account = "deviceID"

    /// Returns the persistent device UUID, creating and storing it on first call.
    /// Survives app deletion because keychain items are not removed on uninstall by default.
    static var deviceID: String {
        if let existing = read() { return existing }
        let new = UUID().uuidString
        write(new)
        return new
    }

    // MARK: - Keychain helpers

    private static func read() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        return value
    }

    private static func write(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData: data
        ]
        // Try add first; if the item already exists, update it.
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account
            ]
            SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        }
    }
}
