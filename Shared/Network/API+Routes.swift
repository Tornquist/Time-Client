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
    
    func getToken(withEmail email: String, andPassword password: String, completionHandler: @escaping (Token?, Error?) -> ()) {
        // username is part of the oauth spec.
        // email is used for a consistent interface within the app. (authenticate/register/getToken)
        let body = [
            "grant_type" : "password",
            "username": email,
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
    
    func updateUser(withID id: Int, setEmail email: String, completionHandler: @escaping (User?, Error?) -> ()) {
        let body: [String: Any] = ["email": email]
        PUT("/users/\(id)", body, completion: completionHandler)
    }
    
    func updateUser(withID id: Int, changePasswordFrom oldPassword: String, to newPassword: String, completionHandler: @escaping (User?, Error?) -> ()) {
        let body: [String: Any] = ["old_password": oldPassword, "new_password": newPassword]
        PUT("/users/\(id)", body, completion: completionHandler)
    }
    
    // MARK: - Accounts
    
    func createAccount(completionHandler: @escaping (Account?, Error?) -> ()) {
        POST("/accounts", completion: completionHandler)
    }
    
    func getAccounts(completionHandler: @escaping ([Account]?, Error?) -> ()) {
        GET("/accounts", completion: completionHandler)
    }
    
    func getAccount(withID id: Int, completionHandler: @escaping (Account?, Error?) -> ()) {
        GET("/accounts/\(id)", completion: completionHandler)
    }
    
    // MARK: - Categories
    
    func getCategories(completionHandler: @escaping ([Category]?, Error?) -> ()) {
        GET("/categories", completion: completionHandler)
    }
    
    func getCategories(forAccountID accountID: Int, completionHandler: @escaping ([Category]?, Error?) -> ()) {
        GET("/categories", urlComponents: ["account_id": String(accountID)], completion: completionHandler)
    }
    
    func createCategory(withName name: String, under parent: Category, completionHandler: @escaping (Category?, Error?) -> ()) {
        let body: [String: Any] = ["name": name, "parent_id": parent.id, "account_id": parent.accountID]
        
        POST("/categories", body, auth: true, encoding: .json, completion: completionHandler)
    }
    
    func getCategory(withID id: Int, completionHandler: @escaping (Category?, Error?) -> ()) {
        GET("/categories/\(id)", completion: completionHandler)
    }
    
    func moveCategory(_ category: Category, toParent parent: Category, completionHandler: @escaping (Category?, Error?) -> ()) {
        let body: [String: Any] = ["parent_id": parent.id, "account_id": parent.accountID]
        
        PUT("/categories/\(category.id)", body, completion: completionHandler)
    }
    
    func renameCategory(_ category: Category, withName name: String, completionHandler: @escaping (Category?, Error?) -> ()) {
        let body: [String: Any] = ["name": name]
        
        PUT("/categories/\(category.id)", body, completion: completionHandler)
    }
    
    func deleteCategory(withID id: Int, andChildren deleteChildren: Bool, completionHandler: @escaping (Error?) -> ()) {
        let body: [String: Any] = ["delete_children": deleteChildren]

        DELETE("/categories/\(id)", body, completion: completionHandler)
    }
    
    // MARK: - Entries
    
    func getEntries(completionHandler: @escaping ([Entry]?, Error?) -> ()) {
        GET("/entries", completion: completionHandler)
    }
    
    func getEntryChanges(after: Date, completionHandler: @escaping ([Entry]?, Error?) -> ()) {
        let urlComponents: [String: String] = [
            "after": DateHelper.isoStringFrom(date: after),
            "reference": "update",
            "deleted": "true"
        ]
        GET("/entries", urlComponents: urlComponents, completion: completionHandler)
    }
    
    func recordEvent(for category: Category, completionHandler: @escaping (Entry?, Error?) -> ()) {
        let timezone = TimeZone.autoupdatingCurrent.identifier
        let body: [String: Any] = ["category_id": category.id, "type": EntryType.event.rawValue, "timezone": timezone]
        POST("/entries", body, auth: true, encoding: .json, completion: completionHandler)
    }
    
    func updateRange(for category: Category, with action: EntryAction, completionHandler: @escaping (Entry?, Error?) -> ()) {
        let timezone = TimeZone.autoupdatingCurrent.identifier
        let body: [String: Any] = ["category_id": category.id, "type": EntryType.range.rawValue, "action": action.rawValue, "timezone": timezone]
        POST("/entries", body, auth: true, encoding: .json, completion: completionHandler)
    }
    
    func getEntry(withID id: Int, completionHandler: @escaping (Entry?, Error?) -> ()) {
        GET("/entries/\(id)", completion: completionHandler)
    }
    
    func updateEntry(with id: Int, setCategory category: Category? = nil, setType type: EntryType? = nil, setStartedAt startedAt: Date? = nil, setStartedAtTimezone startedAtTimezone: String? = nil, setEndedAt endedAt: Date? = nil, setEndedAtTimezone endedAtTimezone: String? = nil, completionHandler: @escaping (Entry?, Error?) -> ()) {
        
        var body: [String: Any] = [:]
        if category != nil { body["category_id"] = category!.id }
        if type != nil { body["type"] = type!.rawValue }
        if startedAt != nil { body["started_at"] = DateHelper.isoStringFrom(date: startedAt!) }
        if startedAtTimezone != nil { body["started_at_timezone"] = startedAtTimezone }
        if endedAt != nil { body["ended_at"] = DateHelper.isoStringFrom(date: endedAt!) }
        if endedAtTimezone != nil { body["ended_at_timezone"] = endedAtTimezone }
        
        PUT("/entries/\(id)", body, completion: completionHandler)
    }
    
    func deleteEntry(withID id: Int, completionHandler: @escaping (Error?) -> ()) {
        DELETE("/entries/\(id)", completion: completionHandler)
    }
    
    // MARK: - Importing Data
    
    func getImportRequests(completionHandler: @escaping ([FileImporter.Request]?, Error?) -> ()) {
        GET("/import", completion: completionHandler)
    }
    
    func getImportRequest(withID id: Int, completionHandler: @escaping (FileImporter.Request?, Error?) -> ()) {
        GET("/import/\(id)", completion: completionHandler)
    }
    
    func importData(from fileImporter: FileImporter, completionHandler: @escaping (FileImporter.Request?, Error?) -> ()) {
        guard let jsonData = fileImporter.asJson() else {
            completionHandler(nil, TimeError.unableToSendRequest("Missing data"))
            return
        }
        
        // Empty root will map all root.children to top level
        let body: [String: Any] = [
            "name": "",
            "events": [],
            "ranges": [],
            "children": jsonData
        ]

        POST("/import", body, auth: true, encoding: .json, completion: completionHandler)
    }
}
