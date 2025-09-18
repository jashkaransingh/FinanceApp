//
//  KeychainHelper.swift
//  Finance App
//
//  Created by Jas  on 7/28/25.
//

import Foundation
import Security

final class KeychainHelper {
    
    static let standard = KeychainHelper()
    private init() {}
    
    /// Saves/overwrites a small secret string for a (service, account) pair
    func save(_ value: String, service: String, account: String) {
        let data = Data(value.utf8)
        // 1) Create query
        let query: [String:Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data
        ]
        // 2) Delete any existing item
        SecItemDelete(query as CFDictionary)
        // 3) Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Reads a secret previously saved for (service, account)
    func read(service: String, account: String) -> String? {
        let query: [String:Any] = [
            kSecClass as String         : kSecClassGenericPassword,
            kSecAttrService as String   : service,
            kSecAttrAccount as String   : account,
            kSecReturnData as String    : true,
            kSecMatchLimit as String    : kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }
    
    /// Deletes the secret stored for (service, account).
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

