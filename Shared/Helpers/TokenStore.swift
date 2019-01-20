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
    static let tag = prefix + ".token"
    
    static func getToken() -> Token? {
        let getQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: TokenStore.tag,
            kSecReturnRef as String: true
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        guard status == errSecSuccess else {
            print("SecItemCopyMatchingStatus: \(status)")
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
        guard let tokenData = try? JSONEncoder().encode(token) else {
            return false
        }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: TokenStore.tag,
            kSecValueData as String: tokenData
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if (status != errSecSuccess) {    // Always check the status
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Write failed: \(err)")
            }
            return false
        } else {
            return true
        }
    }
}
