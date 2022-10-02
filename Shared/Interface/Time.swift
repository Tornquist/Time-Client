//
//  Time.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

public struct TimeConfig {
    public var serverURL: String? = nil
    public var containerURL: String? = nil
    public var userDefaultsSuite: String? = nil
    public var keychainGroup: String? = nil
    public var tokenIdentifier: String? = nil
    
    public init(
        serverURL: String? = nil,
        containerURL: String? = nil,
        userDefaultsSuite: String? = nil,
        keychainGroup: String? = nil,
        tokenIdentifier: String? = nil
    ) {
        self.serverURL = serverURL
        self.containerURL = containerURL
        self.userDefaultsSuite = userDefaultsSuite
        self.keychainGroup = keychainGroup
        self.tokenIdentifier = tokenIdentifier
    }
}

public class Time {

    /**
        The system-wide Time singleton.

        This property will return the existing singleton or initialize and return a new one.
        If you wish to configure the singleton properties (server url, data container, keychain, etc.)
        it is best to first configure the singleton using Time.configureShared(...) prior to fetching this
        value.
     
        A fetch followed by a configure may reset system data (such as the data store) if the server url
        were to be different, but the local data url was the same.
    */
    public static var shared: Time {
        if Time._shared == nil {
            Time._shared = Time(config: TimeConfig(), withAPI: API.shared)
        }
        return Time._shared!
    }
    static var _shared: Time? = nil
    
    let api: API
    let config: TimeConfig
    let tokenStore: TokenStore
    public var store: Store
    public var analyzer: Analyzer
    
    // Control Flow
    var reauthenticating: Bool = false
    
    init(config: TimeConfig, withAPI apiClient: API, lowMemoryMode: Bool = false) {
        self.api = apiClient
        self.config = config
        self.tokenStore = TokenStore(config: config)
        self.store = Store(config: config, api: self.api)
        self.analyzer = Analyzer(store: store, lowMemoryMode: lowMemoryMode)
        
        if let url = config.serverURL {
            let updatedURL = self.api.set(url: url)
            if updatedURL { self.deauthenticate() }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(autoRefreshedToken), name: .TimeAPIAutoRefreshedToken, object: self.api)
        NotificationCenter.default.addObserver(self, selector: #selector(autoRefreshFailed), name: .TimeAPIAutoRefreshFailed, object: self.api)
    }
    
    public static func configureShared(_ config: TimeConfig, lowMemoryMode: Bool = false) {
        API.configureShared(config)
        Time._shared = Time(config: config, withAPI: API.shared, lowMemoryMode: lowMemoryMode)
    }
    
    /**
        Initializing a time instance will configure it for full active usage

        This will fetch and restore tokens cached in the keychain. It is only safe to call while
        the app is open and in focus. Background usage of this method may result in a failure
        to complete initialization.
     
        Read access to previous time data is supported without calling this method.
    */
    public func initialize(completionHandler: ((Error?) -> ())? = nil) {
        guard self.api.token == nil else {
            completionHandler?(nil)
            return
        }
        
        guard let fetchedToken = self.tokenStore.getToken() else {
            completionHandler?(TimeError.tokenNotFound)
            return
        }
        
        self.api.token = fetchedToken
        // No special success handling. Token already stored
        completionHandler?(nil)
    }
    
    public func authenticate(email: String, password: String, completionHandler: ((Error?) -> ())? = nil) {
        let startingUserID = self.api.token?.userID
        
        self.api.getToken(withEmail: email, andPassword: password) { (token, error) in
            guard error == nil else {
                completionHandler?(error)
                return
            }
            
            guard token != nil else {
                completionHandler?(TimeError.tokenNotFound)
                return
            }
            
            if self.reauthenticating {
                let endingUserID = self.api.token?.userID
                let differentUser = startingUserID != endingUserID
                if differentUser {
                    self.store.resetDisk()
                    self.store = Store(config: self.config, api: self.api)
                    self.analyzer = Analyzer(store: self.store)
                }
                self.reauthenticating = false
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
        _ = self.tokenStore.storeToken(token)
        self.api.token = token
        completionHandler?(nil)
    }
    
    public func deauthenticate() {
        _ = self.tokenStore.deleteToken()
        self.store.resetDisk()
        self.store = Store(config: self.config, api: self.api)
        self.analyzer = Analyzer(store: self.store)
        self.api.token = nil
    }
    
    // MARK: - Notification Center
    
    @objc func autoRefreshedToken() {
        guard let token = self.api.token else {
            return
        }
        
        _ = self.tokenStore.storeToken(token)
    }
    
    @objc func autoRefreshFailed() {
        self.reauthenticating = true
        NotificationCenter.default.post(name: .TimeUserSignInNeeded, object: self)
    }
}
