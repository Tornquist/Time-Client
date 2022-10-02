//
//  Warehouse.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/7/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation
import Combine
import TimeSDK
import WidgetKit

class Warehouse: ObservableObject {
    
    private static var _shared: Warehouse? = nil
    static var shared: Warehouse {
        get {
            if _shared == nil {
                _shared = Warehouse(for: Time.shared)
            }
            
            return _shared!
        }
    }
    
    var time: Time? = nil
    var storeCancellable: AnyCancellable?
    var entries: [Entry] {
        return self.time?.store.entries ?? []
    }
    var accountTrees: [CategoryTree] {
        return self.time?.store.accountTrees ?? []
    }
    
    @Published var recentCategories: [CategoryTree] = []
    @Published var recentCategoryIsRange: [Bool] = []
    
    @Published var openCategoryIDs: [Int] = []

    @Published var isRefreshing: Bool = false
    
    init() { }
    
    convenience init(for time: Time) {
        self.init()
        
        self.time = time
        self.storeCancellable = self.time!.store.objectWillChange.sink { self.objectWillChange.send() }

        self.registerNotifications()
        self.loadData()
    }
    
    // MARK: - Display Helpers
    
    func getName(for categoryID: Int?) -> String {
        let category = self.time?.store.categories.first(where: { $0.id == categoryID })
        return self.getName(for: category)
    }
    
    func getName(for category: TimeSDK.Category?) -> String {
        guard category != nil else {
            return NSLocalizedString("Unknown", comment: "")
        }
        let isAccount = category!.parentID == nil
        let name = isAccount ? NSLocalizedString("Account \(category!.accountID)", comment: "") : category!.name
        return name
    }
    
    func getParentHierarchyName(for categoryID: Int?) -> String {
        guard
            let categoryID,
            let categoryTree = self.time?.store.categoryTrees.map({ (key: Int, value: CategoryTree) in
                return value.findItem(withID: categoryID)
            }).filter({ $0 != nil }).first,
            let categoryTree else {
            return ""
        }
        return self.getParentHierarchyName(categoryTree)
    }
    
    func getParentHierarchyName(_ tree: CategoryTree) -> String {
        var parentNameParts: [String] = []
        var position = tree.parent
        while position != nil {
            // Make sure exists and is not root
            if position != nil && position?.parent != nil {
                parentNameParts.append(position!.node.name)
            }
            position = position?.parent
        }
                
        let possibleParentName = parentNameParts.reversed().joined(separator: " > ")
        let parentName = possibleParentName.count > 0 ? possibleParentName : NSLocalizedString("Account \(tree.node.accountID)", comment: "")
        return parentName
    }

    func showChildrenOf(_ category: TimeSDK.Category) {
        if let accountTree = self.time?.store.categoryTrees[category.accountID],
           let categoryLeaf = accountTree.findItem(withID: category.id) {
            var parent: CategoryTree? = categoryLeaf
            while parent != nil {
                parent?.toggleExpanded(forceTo: true)
                parent = parent?.parent
            }
        }
    }
    
    // MARK: - Refresh All
    
    func loadData(refresh: Bool = false) {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
    
        let completion: (Error?) -> Void = { error in
            self.refreshAllCalculations()
        }
        
        let networkMode: Store.NetworkMode = refresh ? .refreshAll : .asNeeded
        time?.store.getCategories(networkMode) { (categories, error) in completion(error) }
        time?.store.getEntries(networkMode) { (entries, error) in completion(error) }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryRecorded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryModified, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryDeleted, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteImportRequest), name: .TimeImportRequestCompleted, object: nil)
    }

    @objc private func handleEntryNotification(_ notification:Notification) {
        self.refreshAllCalculations()
    }
    
    private func refreshAllCalculations() {
        self.calculateRecentCategories()
        self.calculateOpenCategories()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @objc private func didCompleteImportRequest(_ notification:Notification) {
        // TODO: Identify if this is still needed with time as an ObservableObject
        self.loadData(refresh: true)
    }
        
    // MARK: - Recents
    
    private func calculateRecentCategories() {
        enum RecentSortMode {
            case date
            case name
        }
        
        let maxDays = 7 // Max time
        let maxResults = 5 // Max recent entries
        let sortMode: RecentSortMode = .name
        
        let cutoff = Date().addingTimeInterval(Double(-maxDays * 24 * 60 * 60))

        time?.store.getEntries(after: cutoff) { (entries, error) in
            guard let entries = entries, error == nil else {
                return
            }
            
            let orderedEntries = entries.sorted(by: { $0.startedAt > $1.startedAt })
            let orderedCategoryIDs = orderedEntries.map({ $0.categoryID })
            var reducedOrderedIDs: [Int] = []
            orderedCategoryIDs.forEach { (id) in
                guard !reducedOrderedIDs.contains(id) else { return }
                reducedOrderedIDs.append(id)
            }
            
            let recentCategoryIDs = reducedOrderedIDs.prefix(maxResults)
                    
            let recentCategories = recentCategoryIDs.compactMap { (id) -> CategoryTree? in
                guard
                    let category = self.time?.store.categories.first(where: { $0.id == id }),
                    let root = self.time?.store.categoryTrees[category.accountID],
                    let categoryTree = root.findItem(withID: category.id)
                else { return nil }
                
                return categoryTree
            }
            
            Mainify {
                switch sortMode {
                    case .date:
                        // Date sorting is default
                        self.recentCategories = recentCategories
                    case .name:
                        self.recentCategories = recentCategories.sorted { $0.node.name < $1.node.name }
                }
                
                self.recentCategoryIsRange = self.recentCategories.map({ (category) -> Bool in
                    let firstItem = orderedEntries.first(where: { $0.categoryID == category.id })
                    return firstItem?.type == .range
                })
            }
        }
    }
    
    private func calculateOpenCategories() {
        guard let openEntries = self.time?.store.entries.filter({ (entry) -> Bool in
            return entry.type == .range && entry.endedAt == nil
        }) else {
            return
        }
        let categoryIDs = openEntries.map({ $0.categoryID })
        let dedupedIDs = Array(Set(categoryIDs))
        
        self.openCategoryIDs = dedupedIDs
    }
    
    // MARK: - Debug Support
   
    #if DEBUG
    static func getPreviewWarehouse() -> Warehouse {
        let data = """
    [
        {"id": 1, "parent_id": null, "account_id": 1, "name": "root"},
        {"id": 2, "parent_id": 1, "account_id": 1, "name": "Life"},
        {"id": 3, "parent_id": 2, "account_id": 1, "name": "Class"},
        {"id": 4, "parent_id": 3, "account_id": 1, "name": "Data Science"},
        {"id": 5, "parent_id": 3, "account_id": 1, "name": "Machine Learning A-Z"},
        {"id": 6, "parent_id": 2, "account_id": 1, "name": "HOA"},
        {"id": 7, "parent_id": 2, "account_id": 1, "name": "Personal"},
        {"id": 8, "parent_id": 7, "account_id": 1, "name": "Website"},
        {"id": 9, "parent_id": 1, "account_id": 1, "name": "Side Projects"},
        {"id": 10, "parent_id": 9, "account_id": 1, "name": "Keyboard"},
        {"id": 11, "parent_id": 9, "account_id": 1, "name": "Time"},
        {"id": 12, "parent_id": 9, "account_id": 1, "name": "Uplink"},
        {"id": 13, "parent_id": 1, "account_id": 1, "name": "Work"},
        {"id": 14, "parent_id": 13, "account_id": 1, "name": "Job A"},
        {"id": 15, "parent_id": 13, "account_id": 1, "name": "Job B"},
        {"id": 16, "parent_id": 13, "account_id": 1, "name": "Job C"},
        {"id": 17, "parent_id": null, "account_id": 2, "name": "root"},
        {"id": 18, "parent_id": 17, "account_id": 2, "name": "A"},
        {"id": 19, "parent_id": 17, "account_id": 2, "name": "B"}
    ]
    """
        
        let decoder = JSONDecoder()
        let categories = try! decoder.decode([TimeSDK.Category].self, from: data.data(using: .utf8)!)
        let trees = CategoryTree.generateFrom(categories)
        let store = Warehouse()
        
        store.recentCategories = [
            trees[0].findItem(withID: 11)!, // time
            trees[0].findItem(withID: 8)!, // website
            trees[0].findItem(withID: 13)! // work
        ]
        
        store.openCategoryIDs = [11]
        
        return store
    }
    #endif
}
