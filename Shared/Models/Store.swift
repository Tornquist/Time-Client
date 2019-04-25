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
    
    private var staleTrees: Bool = false
    private var staleAccountIDs: Bool = false
    
    private var _accountIDs: [Int] = []
    public var accountIDs: [Int] {
        let hasCategories = self.categories.count != 0
        let hasAccountIDs = self._accountIDs.count > 0
        let needsGeneration = self.staleAccountIDs || (hasCategories && !hasAccountIDs)
        
        if needsGeneration { self.regenerateAccountIDs() }
        
        return self._accountIDs
    }

    public var categories: [Category] = []
    
    private var _categoryTrees: [Int: CategoryTree] = [:]
    public var categoryTrees: [Int:CategoryTree] {
        let hasCategories = self.categories.count != 0
        let hasTrees = self._categoryTrees.count > 0
        let needsGeneration = self.staleTrees || (hasCategories && !hasTrees)
        
        if needsGeneration { self.regenerateTrees() }
        
        return self._categoryTrees
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
                self.staleTrees = true
                self.staleAccountIDs = true
            }
            completionHandler(categories, error)
        }
    }
    
    public func addCategory(withName name: String, to parent: Category, completion: ((Bool) -> Void)?) {
        self.api.createCategory(withName: name, under: parent) { (category, error) in
            if category != nil {
                self.categories.append(category!)
                self.staleTrees = true
                self.staleAccountIDs = true
            }
            
            completion?(error == nil)
        }
    }
    
    public func renameCategory(_ category: Category, to newName: String, completion: ((Bool) -> Void)?) {
        self.api.renameCategory(category, withName: newName) { (newCategory, error) in
            guard error == nil else {
                completion?(false)
                return
            }
            
            category.name = newName
            completion?(true)
        }
    }
    
    public func deleteCategory(withID id: Int, andChildren deleteChildren: Bool, completion: ((Bool) -> Void)?) {
        self.api.deleteCategory(withID: id, andChildren: deleteChildren) { (error) in
            guard error == nil else {
                completion?(false)
                return
            }
            
            guard
                let category = self.categories.first(where: { $0.id == id }),
                let tree = self.categoryTrees[category.accountID],
                let categoryTree = tree.findItem(withID: category.id)
                else {
                    // Deleted, but items are not local. Inconsistent state
                    completion?(true)
                    return
            }
            
            if deleteChildren {
                let allChildren = categoryTree.asList()
                let filteredCategories = self.categories.filter({ (category) -> Bool in
                    let inFilterSet = allChildren.contains(where: { (referenceCategory) -> Bool in
                        return referenceCategory.id == category.id
                    })
                    return !inFilterSet
                })
                if let safeChildren = categoryTree.parent?.children.filter({ $0.node.id != categoryTree.node.id }) {
                    categoryTree.parent?.children = safeChildren
                }
                self.categories = filteredCategories
            } else {
                let filteredCategories = self.categories.filter({ (testCategory) -> Bool in
                    return testCategory.id != category.id
                })
                let elevateChildren = categoryTree.children
                if var safeChildren = categoryTree.parent?.children.filter({ $0.node.id != categoryTree.node.id }) {
                    safeChildren.append(contentsOf: elevateChildren)
                    categoryTree.parent?.children = safeChildren
                    elevateChildren.forEach({ (child) in
                        child.parent = categoryTree.parent
                    })
                    categoryTree.parent?.sortChildren()
                }
                self.categories = filteredCategories
            }
            completion?(true)
        }
    }
    
    private func regenerateTrees() {
        let trees = CategoryTree.generateFrom(self.categories)
        var treeMapping: [Int: CategoryTree] = [:]
        
        trees.forEach { (tree) in
            treeMapping[tree.node.accountID] = tree
        }
        
        self._categoryTrees = treeMapping
        self.staleTrees = false
    }
    
    private func regenerateAccountIDs() {
        let sortedIDs = Array(Set(categories.map({ $0.accountID }))).sorted()
        self._accountIDs = sortedIDs
    }
}
