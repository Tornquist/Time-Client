//
//  TokenStore.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/20/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class TokenStore {
    
    let config: TimeConfig
    
    static let prefix = "com.nathantornquist.Time"
    static let description = "Authentication and Refresh tokens for Time Server"
    
    private let defaultTag = "token"
    
    var tag: String {
        return self.config.tokenIdentifier ?? self.defaultTag
    }
    
    init(config: TimeConfig) {
        self.config = config
    }
    
    // MARK: - Query Support
    
    private enum QueryType {
        case get
        case add
        case delete
    }
    
    private func getQuery(type: QueryType, withUserID userID: Int = 0, andData data: String = "") -> [String: Any] {
        var base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(TokenStore.prefix).\(self.tag)"
        ]
        
        if let group = config.keychainGroup {
            base[kSecAttrAccessGroup as String] = group as AnyObject
        }
        
        switch type {
        case .get:
            base[kSecReturnData as String] = true
            base[kSecMatchLimit as String] = kSecMatchLimitOne
        case .add:
            base[kSecAttrAccount as String] = "User \(userID) - \(TokenStore.prefix)"
            base[kSecAttrComment as String] = TokenStore.description
            base[kSecAttrLabel as String] = "Time"
            base[kSecValueData as String] = data.data(using: .utf8)
        case .delete:
            break
        }
        
        return base
    }
    
    // MARK: - External Interface
    
    func getToken() -> Token? {
        let query = self.getQuery(type: .get) as CFDictionary
        
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
    
    func storeToken(_ token: Token) -> Bool {
        guard let tokenData = try? JSONEncoder().encode(token),
            let tokenString = String(data: tokenData, encoding: String.Encoding.utf8) else {
            return false
        }
        
        _ = self.deleteToken()
        
        let query = self.getQuery(type: .add, withUserID: token.userID, andData: tokenString) as CFDictionary
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }
    
    func deleteToken() -> Bool {
        let query = self.getQuery(type: .delete) as CFDictionary
        let status = SecItemDelete(query)
        return status == errSecSuccess
    }
}
