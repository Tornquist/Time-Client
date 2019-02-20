//
//  API+Routes.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/12/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension API {
    
    // MARK: - Tokens
    
    func getToken(withUsername username: String, andPassword password: String, completionHandler: @escaping (Token?, Error?) -> ()) {
        let body = [
            "grant_type" : "password",
            "username": username,
            "password": password
        ]
        POST("/oauth/token", body, auth: false, encoding: .formUrlEncoded, completion: completionHandler) { (token) in
            self.token = token
        }
    }
    
    func refreshToken(completionHandler: @escaping (Token?, Error?) -> ()) {
        guard let token = self.token else {
            completionHandler(nil, TimeError.unableToSendRequest("Missing token"))
            return
        }
        
        let body = [
            "grant_type" : "refresh_token",
            "refresh_token": token.refresh
        ]
        POST("/oauth/token", body, auth: false, encoding: .formUrlEncoded, completion: completionHandler) { (token) in
            self.token = token
        }
    }
    
    // MARK: - Users
    
    func createUser(withEmail email: String, andPassword password: String, completionHandler: @escaping (User?, Error?) -> ()) {
        POST("/users", ["email": email, "password": password], auth: false, completion: completionHandler)
    }
    
    // MARK: - Accounts
    
    func createAccount(completionHandler: @escaping (Account?, Error?) -> ()) {
        POST("/accounts", completion: completionHandler)
    }
    
    func getAccounts(completionHandler: @escaping ([Account]?, Error?) -> ()) {
        GET("/accounts", completion: completionHandler)
    }
    
    // MARK: - Categories
    
    func getCategories(completionHandler: @escaping ([Category]?, Error?) -> ()) {
        GET("/categories", completion: completionHandler)
    }
    
    func createCategory(withName name: String, under parent: Category, completionHandler: @escaping (Category?, Error?) -> ()) {
        
        let body: [String: Any] = ["name": name, "parent_id": parent.id, "account_id": parent.accountID]
        
        POST("/categories", body, auth: true, encoding: .json, completion: completionHandler)
    }
    
    func moveCategory(_ category: Category, toParent parent: Category, completionHandler: @escaping (Category?, Error?) -> ()) {
        
        let body: [String: Any] = ["parent_id": parent.id, "account_id": parent.accountID]
        
        PUT("/categories/\(category.id)", body, completion: completionHandler)
    }
}
