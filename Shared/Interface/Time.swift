//
//  Time.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

public class Time {
    
    public static let shared = Time()
    
    var token: Token? = nil
    
    public init() { }
    
    public func isAuthenticated() -> Bool {
        guard token != nil else { return false }
        let now = Date()
        guard now < token!.expiration else { return false }
        return true
    }
    
    public func canRefresh() -> Bool {
        return token != nil
    }
    
    public func authenticate(username: String, password: String, completionHandler: ((Error?) -> ())? = nil) {
        API.shared.getToken(withUsername: username, andPassword: password) { (token, error) in
            if error == nil && token != nil {
                self.token = token
            }
            completionHandler?(error)
        }
    }
}
