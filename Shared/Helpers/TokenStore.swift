//
//  TokenStore.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/20/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class TokenStore {
    static let prefix = "com.nathantornquist.Time"
    static let description = "Authentication and Refresh tokens for Time Server"
    static private let defaultTag = "token"
    
    // MARK: - Query Support
    
    private enum QueryType {
        case get
        case add
        case delete
    }
    
    static private func getQuery(type: QueryType, withTag tag: String = TokenStore.defaultTag, withUserID userID: Int = 0, andData data: String = "") -> [String: Any] {
        var base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(TokenStore.prefix).\(tag)",
        ]
        
        switch type {
        case .get:
            base[kSecReturnData as String] = true
            base[kSecMatchLimit as String] = kSecMatchLimitOne
        case .add:
            base[kSecAttrAccount as String] = "User \(userID) - \(TokenStore.prefix)"
            base[kSecAttrComment as String] = TokenStore.description
            base[kSecAttrLabel as String] = "Time"
            base[kSecValueData as String] = data
        case .delete:
            break
        }
        
        return base
    }
    
    // MARK: - External Interface
    
    static func getToken(withTag tag: String = TokenStore.defaultTag) -> Token? {
        let query = TokenStore.getQuery(type: .get, withTag: tag) as CFDictionary
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query, &item)
        
        guard
            status == errSecSuccess,
            let data = item as? Data,
            let token = try? JSONDecoder().decode(Token.self, from: data)
        else {
            return nil
        }

        return token
    }
    
    static func storeToken(_ token: Token, withTag tag: String = TokenStore.defaultTag) -> Bool {
        guard let tokenData = try? JSONEncoder().encode(token),
            let tokenString = String(data: tokenData, encoding: String.Encoding.utf8) else {
            return false
        }
        
        _ = TokenStore.deleteToken(withTag: tag)
        
        let query = TokenStore.getQuery(type: .add, withTag: tag, withUserID: token.userID, andData: tokenString) as CFDictionary
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }
    
    static func deleteToken(withTag tag: String = TokenStore.defaultTag) -> Bool {
        let query = TokenStore.getQuery(type: .delete, withTag: tag) as CFDictionary
        let status = SecItemDelete(query)
        return status == errSecSuccess
    }
}
