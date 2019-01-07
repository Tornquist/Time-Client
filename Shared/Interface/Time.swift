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
    
    public func isAuthenticated() -> Bool {
        return token != nil
    }
    
    public func authenticate(email: String, password: String, completionHandler: ((Error?) -> ())? = nil) {
        API.shared.getToken(with: email, and: password) { (token, error) in
            if error == nil && token != nil {
                self.token = token
            }
            completionHandler?(error)
        }
    }
}
