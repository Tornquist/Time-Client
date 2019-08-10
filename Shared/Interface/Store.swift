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

    private var _hasFetchedEntries: Bool = false
    public var entries: [Entry] = []
    
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
    
    // MARK: - Accounts
    
    public func createAccount(completion: ((Account?, Error?) -> ())?) {
        self.api.createAccount { (newAccount, error) in
            guard error == nil && newAccount != nil else {
                let returnError = error ?? TimeError.unableToDecodeResponse
                completion?(nil, returnError)
                return
            }

            self._accountIDs.append(newAccount!.id)
            
            self.api.getCategories(forAccountID: newAccount!.id, completionHandler: { (newCategories, categoryError) in
                guard categoryError == nil && newCategories != nil && newCategories!.count >= 1 else {
                    completion?(newAccount, TimeError.requestFailed("Could not load new categories"))
                    return
                }
                
                self.categories.append(contentsOf: newCategories!)
                
                let newTrees = CategoryTree.generateFrom(newCategories!)
                let tree = newTrees.first(where: { $0.node.accountID == newAccount!.id })
                if tree != nil {
                    self._categoryTrees[newAccount!.id] = tree!
                } else {
                    self.staleTrees = true
                }
                
                completion?(newAccount, nil)
            })
        }
    }
    
    // MARK: - Categories
    
    public func getCategories(refresh: Bool = false, completionHandler: @escaping ([Category]?, Error?) -> ()) {
        guard self.categories.count == 0 || refresh else {
            completionHandler(self.categories, nil)
            return
        }
        
        self.api.getCategories { (categories, error) in
            if categories != nil {
                let existingData = self.categories.sorted(by: { $0.id < $1.id })
                let newData = categories!.sorted(by: { $0.id < $1.id })
                let sameData = existingData == newData
                if !sameData {
                    self.categories = categories!
                    self.staleTrees = true
                    self.staleAccountIDs = true
                }
            }
            completionHandler(categories, error)
        }
    }
    
    public func addCategory(withName name: String, to parent: Category, completion: ((Bool, Category?) -> Void)?) {
        self.api.createCategory(withName: name, under: parent) { (category, error) in
            if category != nil {
                self.categories.append(category!)
                
                let newTree = CategoryTree(category!)
                
                let accountID = parent.accountID
                if let accountTree = self.categoryTrees[accountID],
                    let parentTree = accountTree.findItem(withID: parent.id) {
                    
                    parentTree.children.append(newTree)
                    newTree.parent = parentTree
                    parentTree.sortChildren()
                } else {
                    self.staleTrees = true
                }
            }
            
            completion?(error == nil, category)
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
    
    public func canMove(_ category: Category, to potentialParent: Category) -> Bool {
        // Cannot move to self.
        guard category.id != potentialParent.id else { return false }
        
        // Different accounts mean different trees. Automatic pass.
        guard category.accountID == potentialParent.accountID else { return true }
        
        // Must have reference to move, and potential parent cannot be a child of moving node
        guard
            let accountTree = self.categoryTrees[category.accountID],
            let categoryTree = accountTree.findItem(withID: category.id),
            categoryTree.findItem(withID: potentialParent.id) == nil
            else { return false }
        
        // Cannot move to same parent
        return potentialParent.id != categoryTree.parent?.node.id
    }
    
    public func moveCategory(_ category: Category, to newParent: Category, completion: ((Bool) -> Void)?) {
        self.api.moveCategory(category, toParent: newParent) { (updatedCategory, error) in
            if error == nil {
                category.parentID = newParent.id
                if let sourceTree = self.categoryTrees[category.accountID],
                    let destinationTree = self.categoryTrees[newParent.accountID],
                    let categoryTree = sourceTree.findItem(withID: category.id),
                    let parentTree = destinationTree.findItem(withID: newParent.id) {
                    
                    let allCategories = categoryTree.listCategories()
                    allCategories.forEach({ $0.accountID = newParent.accountID })
                    
                    if categoryTree.parent != nil {
                        categoryTree.parent!.children = categoryTree.parent!.children.filter({ child in
                            return child.node.id != category.id
                        })
                    }
                    parentTree.children.append(categoryTree)
                    categoryTree.parent = parentTree
                    parentTree.sortChildren()
                }
            }
            
            completion?(error == nil)
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
                let allChildren = categoryTree.listCategories()
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
    
    // MARK: - Entries
    
    public func getEntries(refresh: Bool = false, completion: (([Entry]?, Error?) -> ())?) {
        guard !self._hasFetchedEntries || refresh else {
            completion?(self.entries, nil)
            return
        }
        
        self.api.getEntries { (entries, error) in
            if entries != nil {
                self._hasFetchedEntries = true
                self.entries = entries!
            }
            
            completion?(entries, error)
        }
    }
    
    // MARK: Category Interface
    
    public func recordEvent(for category: TimeSDK.Category, completion: ((Bool) -> Void)?) {
        self.api.recordEvent(for: category) { (newEntry, error) in
            guard error == nil && newEntry != nil else {
                completion?(false)
                return
            }
            
            self.entries.append(newEntry!)
            completion?(true)
        }
    }
    
    public func toggleRange(for category: TimeSDK.Category, completion: ((Bool) -> Void)?) {
        let isOpen = self.isRangeOpen(for: category)
        guard isOpen != nil else {
            self.getEntries { (entries, error) in
                guard error == nil else {
                    completion?(false)
                    return
                }
                self.toggleRange(for: category, completion: completion)
            }
            return
        }
        
        let action: EntryAction = isOpen! ? .stop : .start
        self.api.updateRange(for: category, with: action) { (entry, error) in
            guard error == nil && entry != nil else {
                completion?(false)
                return
            }
            
            if action == .start {
                self.entries.append(entry!)
            } else {
                if let updatedEntry = self.entries.first(where: { $0.id == entry!.id }) {
                    updatedEntry.endedAt = entry!.endedAt
                } else {
                    self.entries.append(entry!)
                }
            }
            
            completion?(true)
        }
        
    }
    
    public func isRangeOpen(for category: TimeSDK.Category) -> Bool? {
        guard self._hasFetchedEntries else { return nil }
        
        let openEntry = self.entries.first(where: { $0.categoryID == category.id && $0.type == .range && $0.endedAt == nil })
        return openEntry != nil
    }
    
    // MARK: Entry Interface
    
    public func stop(entry: Entry, completion: ((Bool) -> Void)?) {
        self.update(entry: entry, setEndedAt: Date(), completion: completion)
    }
    
    public func update(entry: Entry, setCategory category: Category? = nil, setType type: EntryType? = nil, setStartedAt startedAt: Date? = nil, setStartedAtTimezone startedAtTimezone: String? = nil, setEndedAt endedAt: Date? = nil, setEndedAtTimezone endedAtTimezone: String? = nil, completion: ((Bool) -> Void)?) {
        guard category != nil || type != nil || startedAt != nil || startedAtTimezone != nil || endedAt != nil || endedAtTimezone != nil else { completion?(true); return }
        guard endedAt == nil || (endedAt != nil && (entry.type == .range || type == .range)) else { completion?(false); return }
        guard endedAtTimezone == nil || (endedAtTimezone != nil && (entry.type == .range || type == .range)) else { completion?(false); return }
        
        self.api.updateEntry(with: entry.id, setCategory: category, setType: type, setStartedAt: startedAt, setStartedAtTimezone: startedAtTimezone, setEndedAt: endedAt, setEndedAtTimezone: endedAtTimezone) { (updatedEntry, error) in
            guard error == nil && updatedEntry != nil else {
                completion?(false)
                return
            }
            
            entry.categoryID = updatedEntry!.categoryID
            entry.type = updatedEntry!.type
            entry.startedAt = updatedEntry!.startedAt
            entry.startedAtTimezone = updatedEntry!.startedAtTimezone
            entry.endedAt = updatedEntry!.endedAt
            entry.endedAtTimezone = updatedEntry!.endedAtTimezone
            completion?(true)
        }
    }
    
    public func delete(entry: Entry, completion: ((Bool) -> Void)?) {
        self.api.deleteEntry(withID: entry.id) { (error) in
            if error == nil,
                let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                self.entries.remove(at: index)
            }
            completion?(error == nil)
        }
    }
    
    // MARK: - Support/Lifecycle Methods
    
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
