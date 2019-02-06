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
        GET("/categories") { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let categories = try JSONDecoder().decode([Category].self, from: data)
                completionHandler(categories, nil)
            } catch {
                print (error)
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
    
    func createCategory(withName name: String, under parent: Category, completionHandler: @escaping (Category?, Error?) -> ()) {
        
        let body: [String: Any] = ["name": name, "parent_id": parent.id, "account_id": parent.accountID]
        
        POST("/categories", body, auth: true, encoding: .json)  { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let category = try JSONDecoder().decode(Category.self, from: data)
                completionHandler(category, nil)
            } catch {
                print (error)
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
}
