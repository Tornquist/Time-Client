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
    
    private var _categoryTree: [CategoryTree] = []
    private var staleTree: Bool = false
    public var categoryTree: [CategoryTree] {
        let hasCategories = self.categories.count != 0
        let hasTree = self._categoryTree.count > 0
        let needsGeneration = self.staleTree || (hasCategories && !hasTree)
        
        if needsGeneration { self.regenerateTree() }
        
        return self._categoryTree
    }
    
    
    init(api: API) {
        self.api = api
    }
    
    public func getCategories(refresh: Bool = false, completionHandler: @escaping ([Category]?, Error?) -> ()) {
        guard categories.count == 0 || refresh else {
            completionHandler(self.categories, nil)
            return
        }
        
        self.api.getCategories { (categories, error) in
            if categories != nil {
                self.categories = categories!
                self.staleTree = true
            }
            completionHandler(categories, error)
        }
    }
    
    public func addCategory(withName name: String, to parent: Category, completion: ((Bool) -> Void)?) {
        self.api.createCategory(withName: name, under: parent) { (category, error) in
            if category != nil {
                self.categories.append(category!)
                self.staleTree = true
            }
            
            completion?(error == nil)
        }
    }
    
    private func regenerateTree() {
        let newTree = CategoryTree.generateFrom(self.categories)
        self._categoryTree = newTree
        self.staleTree = false
    }
}
