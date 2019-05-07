//
//  Time.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

public class Time {

    static var _shared: Time? = nil
    public static var shared: Time {
        if Time._shared == nil {
            Time._shared = Time(withAPI: API.shared)
        }
        return Time._shared!
    }
    
    let api: API
    let tokenIdentifier: String
    public var store: Store
    
    init(withAPI apiClient: API, andTokenIdentifier tokenIdentifier: String = "token") {
        self.api = apiClient
        self.tokenIdentifier = tokenIdentifier
        self.store = Store(api: self.api)
    }
    
    public func initialize(completionHandler: ((Error?) -> ())? = nil) {
        guard self.api.token == nil else {
            completionHandler?(nil)
            return
        }
        
        guard let fetchedToken = TokenStore.getToken(withTag: self.tokenIdentifier) else {
            completionHandler?(TimeError.tokenNotFound)
            return
        }
        
        self.api.token = fetchedToken
        guard fetchedToken.expiration < Date() else {
            completionHandler?(nil)
            return
        }
        
        self.api.refreshToken { (newToken, error) in
            guard error == nil && newToken != nil else {
                completionHandler?(TimeError.unableToRefreshToken)
                return
            }
            
            self.handleTokenSuccess(token: newToken!, completionHandler: completionHandler)
        }
    }
    
    public func authenticate(email: String, password: String, completionHandler: ((Error?) -> ())? = nil) {
        self.api.getToken(withEmail: email, andPassword: password) { (token, error) in
            guard error == nil else {
                completionHandler?(error)
                return
            }
            
            guard token != nil else {
                completionHandler?(TimeError.tokenNotFound)
                return
            }
            
            self.handleTokenSuccess(token: token!, completionHandler: completionHandler)
        }
    }
    
    public func register(email: String, password: String, completionHandler: ((Error?) -> ())? = nil) {
        self.api.createUser(withEmail: email, andPassword: password) { (_, error) in
            guard error == nil else {
                completionHandler?(error)
                return
            }
            
            // Note: Can hide create success followed by auth failures.
            // Currently 409 (dup email) is the most common unique createUser issue --> A wrapper method
            // to expand and detail specific errors (like Time+Validation) is needed
            self.authenticate(email: email, password: password, completionHandler: completionHandler)
        }
    }
    
    func handleTokenSuccess(token: Token, completionHandler: ((Error?) -> ())? = nil) {
        _ = TokenStore.storeToken(token, withTag: self.tokenIdentifier)
        self.api.token = token
        completionHandler?(nil)
    }
    
    public func deauthenticate() {
        _ = TokenStore.deleteToken(withTag: self.tokenIdentifier)
        self.api.token = nil
    }
}
