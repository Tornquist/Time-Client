//
//  Store.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/15/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class Store {
    
    var api: API
    
    public var categories: [Category] = []
    
    init(api: API) {
        self.api = api
    }
    
    public func getCategories(refresh: Bool = false, completionHandler: @escaping ([Category]?, Error?) -> ()) {
        guard categories.count == 0 || refresh else {
            completionHandler(self.categories, nil)
            return
        }
        
        self.api.getCategories { (categories, error) in
            if categories != nil { self.categories = categories! }
            completionHandler(categories, error)
        }
    }
}
