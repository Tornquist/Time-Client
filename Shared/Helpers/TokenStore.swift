//
//  TokenStore.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/20/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class TokenStore {
    static let prefix = "com.nathantornquist.Time.keys"
    static let tag = (prefix + ".token")
    
    static func getToken() -> Token? {
        let getQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: TokenStore.tag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            print("Not found")
            return nil
        }
        guard status == errSecSuccess else {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Read failed: \(err)")
            } else {
                print("SecItemCopyMatchingStatus: \(status)")
            }
            return nil
        }
        guard let data = item as? Data else {
            print("Unable to cast to data")
            return nil
        }
        let token = try? JSONDecoder().decode(Token.self, from: data)
        return token
    }
    
    static func storeToken(_ token: Token) -> Bool {
        guard let tokenData = try? JSONEncoder().encode(token),
            let tokenString = String(data: tokenData, encoding: String.Encoding.utf8) else {
            return false
        }
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: TokenStore.tag
        ]
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: TokenStore.tag,
            kSecValueData as String: tokenString
        ]
        
        let statusDelete = SecItemDelete(deleteQuery as CFDictionary)
        if (statusDelete != errSecSuccess) {    // Always check the status
            if let err = SecCopyErrorMessageString(statusDelete, nil) {
                print("Delete failed: \(err)")
            }
        }
        
        let statusAdd = SecItemAdd(addQuery as CFDictionary, nil)
        
        if (statusAdd != errSecSuccess) {    // Always check the status
            if let err = SecCopyErrorMessageString(statusAdd, nil) {
                print("Write failed: \(err)")
            }
            return false
        } else {
            return true
        }
    }
}
