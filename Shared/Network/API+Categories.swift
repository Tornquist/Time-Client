//
//  API+Categories.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension API {
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
