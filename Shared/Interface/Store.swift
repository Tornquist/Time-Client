//
//  Store.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/15/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class Store {
    
    private enum StoreKeys: String {
        case entriesSyncTimestamp = "time-entries-sync-timestamp"
        case categoriesSyncTimestamp = "time-categories-sync-timestamp"
    }
    
    public enum NetworkMode {
        case asNeeded
        case fetchChanges
        case refreshAll
    }
    
    var userDefaultsSuite: String?
    var api: API
    private var archive: Archive
    
    private var userDefaults: UserDefaults {
        return self.userDefaultsSuite != nil
            ? UserDefaults(suiteName: self.userDefaultsSuite!)!
            : UserDefaults()
    }
    
    private var hasInitialized: Bool = false
    
    private var staleTrees: Bool = false
    private var staleAccountIDs: Bool = false
    
    private var _accountIDs: [Int] = [] {
        didSet { self.archive(data: self._accountIDs) }
    }
    public var accountIDs: [Int] {
        let hasCategories = self.categories.count != 0
        let hasAccountIDs = self._accountIDs.count > 0
        let needsGeneration = self.staleAccountIDs || (hasCategories && !hasAccountIDs)
        
        if needsGeneration { self.regenerateAccountIDs() }
        
        return self._accountIDs
    }

    private var _hasFetchedEntries: Bool = false
    public var entries: [Entry] = [] {
        didSet { self.archive(data: self.entries) }
    }
    
    public var categories: [Category] = [] {
        didSet { self.archive(data: self.categories) }
    }
    
    private var _categoryTrees: [Int: CategoryTree] = [:]
    public var categoryTrees: [Int: CategoryTree] {
        let hasCategories = self.categories.count != 0
        let hasTrees = self._categoryTrees.count > 0
        let needsGeneration = self.staleTrees || (hasCategories && !hasTrees)
        
        if needsGeneration { self.regenerateTrees() }
        
        return self._categoryTrees
    }
    
    private var _hasFetchedImportRequests: Bool = false
    public var importRequests: [FileImporter.Request] = []
    
    init(api: API, userDefaultsSuite: String? = nil, containerURL: String? = nil) {
        self.userDefaultsSuite = userDefaultsSuite
        self.api = api
        self.archive = Archive(containerURL: containerURL)
        
        self.restoreDataFromDisk()
        self.hasInitialized = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(categoryArchiveRequested),
            name: .TimeCategoryArchiveRequested,
            object: nil
        )
    }
    convenience init(config: TimeConfig, api: API) {
        self.init(
            api: api,
            userDefaultsSuite: config.userDefaultsSuite,
            containerURL: config.containerURL
        )
    }
    
    // MARK: - System Queues
    
    // Used to avoid race conditions on fetching and setting entries when accessed
    // from both the getCategories and getEntries paths. All other calls are local
    // to their own named stack.
    private let completeSyncCollisonQueue = DispatchQueue(label: "completeSyncCollisonQueue", attributes: .concurrent)
    
    // MARK: - Accounts
    
    public func createAccount(completion: ((Account?, Error?) -> ())?) {
        self.api.createAccount { (newAccount, error) in
            guard error == nil && newAccount != nil else {
                self.handleNetworkError(error)
                let returnError = error ?? TimeError.unableToDecodeResponse
                completion?(nil, returnError)
                return
            }

            self._accountIDs.append(newAccount!.id)
            
            self.api.getCategories(forAccountID: newAccount!.id, completionHandler: { (newCategories, categoryError) in
                guard categoryError == nil && newCategories != nil && newCategories!.count >= 1 else {
                    self.handleNetworkError(error)
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
    
    public func getCategories(_ network: NetworkMode = .asNeeded, completion: (([Category]?, Error?) -> ())? = nil) {
        guard self.categories.count == 0 || network != .asNeeded else {
            completion?(self.categories, nil)
            return
        }
        
        // Note: getCategories does not support distinct
        //       .fetchChanges vs. .refreshAll updates.
        //       The behavior is the same for both.
        
        self.api.getCategories { (categories, error) in
            guard error == nil else {
                // Do not broadcast network warning for background updates
                if network != .fetchChanges {
                    self.handleNetworkError(error)
                }
                completion?(nil, error)
                return
            }
            guard categories != nil else {
                completion?(nil, TimeError.unableToDecodeResponse)
                return
            }
            
            self.recordCategoriesSync()
            let existingData = self.categories.sorted(by: { $0.id < $1.id })
            let newData = categories!.sorted(by: { $0.id < $1.id })
            let sameData = existingData == newData
            if !sameData {
                self.categories = categories!
                self.staleTrees = true
                self.staleAccountIDs = true
                
                self.completeSyncCollisonQueue.sync {
                    let startingEntries = self.entries
                    let currentCategoryIDs = self.categories.map({ $0.id })
                    let endingEntries = startingEntries.filter({ currentCategoryIDs.contains($0.categoryID) })
                    self.entries = endingEntries
                }
            }
            completion?(categories, nil)
        }
    }
    
    public func addCategory(withName name: String, to parent: Category, completion: ((Bool, Category?) -> Void)?) {
        self.api.createCategory(withName: name, under: parent) { (category, error) in
            guard category != nil && error == nil else {
                self.handleNetworkError(error)
                completion?(false, nil)
                return
            }

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
            
            completion?(true, category)
        }
    }
    
    public func renameCategory(_ category: Category, to newName: String, completion: ((Bool) -> Void)?) {
        self.api.renameCategory(category, withName: newName) { (newCategory, error) in
            guard error == nil else {
                self.handleNetworkError(error)
                completion?(false)
                return
            }
            
            category.name = newName
            
            self.archive(data: self.categories)
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
            guard error == nil else {
                self.handleNetworkError(error)
                completion?(false)
                return
            }
        
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
            
            self.archive(data: self.categories)
        
            completion?(true)
        }
    }
    
    public func deleteCategory(withID id: Int, andChildren deleteChildren: Bool, completion: ((Bool) -> Void)?) {
        self.api.deleteCategory(withID: id, andChildren: deleteChildren) { (error) in
            guard error == nil else {
                self.handleNetworkError(error)
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
                let removeIds = [category.id] + allChildren.map({ $0.id })
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
                self.entries = self.entries.filter({ !removeIds.contains($0.categoryID) })
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
                self.entries = self.entries.filter({ $0.categoryID != category.id })
            }
            completion?(true)
        }
    }
    
    // MARK: - Entries
    
    public func getEntries(_ network: NetworkMode = .asNeeded, completion: (([Entry]?, Error?) -> ())? = nil) {
        guard !self._hasFetchedEntries || network != .asNeeded else {
            completion?(self.entries, nil)
            return
        }
        
        let lastSyncDate = self.getEntriesSync()
        let fetchOnlyChanges = self._hasFetchedEntries && network == .fetchChanges && lastSyncDate != nil
        
        let apiCompletion = { (entries: [Entry]?, error: Error?) in
            guard entries != nil && error == nil else {
                // Do not broadcast network warning for background updates
                if network != .fetchChanges {
                    self.handleNetworkError(error)
                }
                let returnError = error ?? TimeError.unableToDecodeResponse
                completion?(nil, returnError)
                return
            }
            
            self.recordEntriesSync()
            self._hasFetchedEntries = true
            
            self.completeSyncCollisonQueue.sync {
                if fetchOnlyChanges {
                    var cleanEntries = self.entries
                    
                    let impactedIDs = entries!.map({ $0.id })
                    cleanEntries.removeAll { impactedIDs.contains($0.id) }
                    let addEntries = entries!.filter({ $0.deleted != true })
                    cleanEntries.append(contentsOf: addEntries)
                    
                    self.entries = cleanEntries
                } else {
                    self.entries = entries!
                }
            }
            
            completion?(self.entries, nil)
        }
        
        if fetchOnlyChanges {
            self.api.getEntryChanges(after: lastSyncDate!, completionHandler: apiCompletion)
        } else {
            self.api.getEntries(completionHandler: apiCompletion)
        }
    }
    
    public func getEntries(after date: Date, completion: (([Entry]?, Error?) -> ())? = nil) {
        self.getEntries(.asNeeded) { (entries, error) in
            guard error == nil else {
                self.handleNetworkError(error)
                completion?(nil, error)
                return
            }
            
            let realEntries = entries ?? []
            let safeEntries = realEntries.filter { (entry) -> Bool in
                if entry.endedAt?.compare(date) == .orderedDescending {
                    return true
                }
                
                if entry.endedAt == nil && entry.type == .range {
                    return true
                }
                
                return entry.startedAt.compare(date) == .orderedDescending
            }
            
            completion?(safeEntries, nil)
        }
    }
    
    // MARK: Category Interface
    
    public func recordEvent(for category: TimeSDK.Category, completion: ((Bool) -> Void)?) {
        self.api.recordEvent(for: category) { (newEntry, error) in
            guard error == nil && newEntry != nil else {
                self.handleNetworkError(error)
                completion?(false)
                return
            }
            
            self.entries.append(newEntry!)
            NotificationCenter.default.post(name: .TimeEntryRecorded, object: newEntry!)
            completion?(true)
        }
    }
    
    public func toggleRange(for category: TimeSDK.Category, completion: ((Bool) -> Void)?) {
        let isOpen = self.isRangeOpen(for: category)
        guard isOpen != nil else {
            self.getEntries { (entries, error) in
                guard error == nil else {
                    self.handleNetworkError(error)
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
                self.handleNetworkError(error)
                completion?(false)
                return
            }
            
            if action == .start {
                self.entries.append(entry!)
                NotificationCenter.default.post(name: .TimeEntryStarted, object: entry!)
            } else {
                if let updatedEntry = self.entries.first(where: { $0.id == entry!.id }) {
                    updatedEntry.endedAt = entry!.endedAt
                    self.archive(data: self.entries)
                    NotificationCenter.default.post(name: .TimeEntryStopped, object: updatedEntry)
                } else {
                    self.entries.append(entry!)
                    NotificationCenter.default.post(name: .TimeEntryStopped, object: entry!)
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
        
        let onlyEndSet = category == nil && type == nil && startedAt == nil && startedAtTimezone == nil && endedAt != nil
        let wasStopAction = onlyEndSet && Date().timeIntervalSince(endedAt!) < 1.0
        
        self.api.updateEntry(with: entry.id, setCategory: category, setType: type, setStartedAt: startedAt, setStartedAtTimezone: startedAtTimezone, setEndedAt: endedAt, setEndedAtTimezone: endedAtTimezone) { (updatedEntry, error) in
            guard error == nil && updatedEntry != nil else {
                self.handleNetworkError(error)
                completion?(false)
                return
            }
            
            entry.categoryID = updatedEntry!.categoryID
            entry.type = updatedEntry!.type
            entry.startedAt = updatedEntry!.startedAt
            entry.startedAtTimezone = updatedEntry!.startedAtTimezone
            entry.endedAt = updatedEntry!.endedAt
            entry.endedAtTimezone = updatedEntry!.endedAtTimezone
            
            self.archive(data: self.entries)
            
            if wasStopAction {
                NotificationCenter.default.post(name: .TimeEntryStopped, object: entry)
            } else {
                NotificationCenter.default.post(name: .TimeEntryModified, object: entry)
            }
            
            completion?(true)
        }
    }
    
    public func delete(entry: Entry, completion: ((Bool) -> Void)?) {
        self.api.deleteEntry(withID: entry.id) { (error) in
            guard error == nil else {
                self.handleNetworkError(error)
                completion?(false)
                return
            }
            

            if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                self.entries.remove(at: index)
            }
            NotificationCenter.default.post(name: .TimeEntryDeleted, object: entry)
            completion?(true)
        }
    }
    
    // MARK: - Import Interface
    
    public func getImportRequests(_ network: NetworkMode = .asNeeded, completion: (([FileImporter.Request]?, Error?) -> ())? = nil) {
        guard !self._hasFetchedImportRequests || network != .asNeeded else {
            completion?(self.importRequests, nil)
            return
        }
        
        self.api.getImportRequests { (requests, error) in
            guard requests != nil && error == nil else {
                completion?(nil, error)
                return
            }
            
            if self.importRequests.count != 0 {
                let requestCompleted = requests!.map({ (newRequest) in
                    let newID = newRequest.id
                    let oldRequest = self.importRequests.first(where: { $0.id == newID })
                    
                    let newAlreadyComplete = oldRequest == nil && newRequest.complete
                    let newRecentlyComplete = oldRequest != nil && !oldRequest!.complete && newRequest.complete
                    
                    return newAlreadyComplete || newRecentlyComplete
                }).reduce(false, { $0 || $1 })

                if requestCompleted {
                    NotificationCenter.default.post(name: .TimeImportRequestCompleted, object: self)
                    
                    // Hard refresh data to display new entries
                    var entriesUpdateDone = false
                    var categoriesUpdateDone = false
 
                    let complete = {
                        guard entriesUpdateDone && categoriesUpdateDone else { return }
                        NotificationCenter.default.post(name: .TimeBackgroundStoreUpdate, object: self)
                    }
                    
                    self.getEntries(.fetchChanges) { (_, _) in
                        entriesUpdateDone = true
                        complete()
                    }
                    self.getCategories(.fetchChanges) { (_, _) in
                        categoriesUpdateDone = true
                        complete()
                    }
                }
            }
            
            self.importRequests = requests!.sorted(by: { (a, b) -> Bool in
                return a.createdAt.compare(b.createdAt) == .orderedDescending
            })
            self._hasFetchedImportRequests = true
            
            completion?(requests, nil)
        }
    }

    public func importData(from importer: FileImporter, completion: ((FileImporter.Request?, Error?) -> ())? = nil) {
        self.api.importData(from: importer) { (request, error) in
            if request != nil && error == nil {
                self.importRequests.insert(request!, at: 0)
                // Do not set _hasFetchedImportRequests.
                //   -> If already true, it is still true.
                //   -> If it was false, there can still be items missing that need fetched.
                
                NotificationCenter.default.post(name: .TimeImportRequestCreated, object: self)
            }
            
            completion?(request, nil)
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
        self.staleAccountIDs = false
    }
    
    private func handleNetworkError(_ error: Error?, _ completionHandler: (() -> ())? = nil) {
        if (error as? TimeError) == TimeError.unableToReachServer {
            if completionHandler != nil {
                completionHandler!()
            } else {
                NotificationCenter.default.post(name: .TimeUnableToReachServer, object: self)
            }
        }
    }
    
    // MARK: - Metrics
    
    public func countEntries(for tree: CategoryTree, includeChildren: Bool) -> Int {
        let specificIDs = [tree.node.id]
        let allIDs = specificIDs + tree.listCategories().map({ $0.id })
        
        return self.entries
            .filter({ (includeChildren ? allIDs : specificIDs).contains($0.categoryID) })
            .count
    }
    
    // MARK: - Archival Support and Integration
    
    @objc private func categoryArchiveRequested(notification: NSNotification) {
        // Only trigger archive for categories managed by store
        guard
            let category = notification.object as? Category,
            self.categories.contains(category)
        else { return }
        self.archive(data: self.categories)
    }
    
    public func resetDisk() {
        _ = self.archive.removeAllData()
    }
    
    private func restoreDataFromDisk() {        
        if let categories: [Category] = self.archive.retrieveData() {
            self.categories = categories
            self.staleTrees = true
        }
        
        if let entries: [Entry] = self.archive.retrieveData() {
            self.entries = entries
            self._hasFetchedEntries = true
        }
        
        if let accountIDs: [Int] = self.archive.retrieveData() {
            self._accountIDs = accountIDs
        } else {
            self.staleAccountIDs = true
        }
    }
    
    private func archive<T>(data: T) where T : Codable {
        guard self.hasInitialized else { return }
        _ = self.archive.record(data)
    }
    
    // MARK: - Remote Syncing
    
    public func fetchRemoteChanges(completion: (() -> ())? = nil) {
        guard self.api.token != nil else { return }

        // Will only update data previously synced. Full fetch must be handled
        // through existing get() interfaces
        
        let lastSyncEntries = self.getEntriesSync()
        let lastSyncCategories = self.getCategoriesSync()
        
        let shouldUpdateEntries = lastSyncEntries != nil
        let shouldUpdateCategories = lastSyncCategories != nil
        let shouldUpdate = shouldUpdateEntries || shouldUpdateCategories
        guard shouldUpdate else { return }
        
        var updateParams: [String: String] = [:]
        if (shouldUpdateEntries) {
            updateParams["entries"] = DateHelper.isoStringFrom(date: lastSyncEntries!, includeMilliseconds: true)
        }
        if (shouldUpdateCategories) {
            updateParams["categories"] = DateHelper.isoStringFrom(date: lastSyncCategories!, includeMilliseconds: true)
        }
        
        // Sync using update params
        var entriesDone: Bool = false
        var categoriesDone: Bool = false
        
        let callComplete: () -> () = {
            guard entriesDone && categoriesDone else { return }
            completion?()
        }
        
        if (shouldUpdateEntries) {
            self.getEntries(.fetchChanges) { (_, _) in
                entriesDone = true
                callComplete()
            }
        } else {
            entriesDone = true
            callComplete()
        }
        
        if (shouldUpdateCategories) {
            self.getCategories(.fetchChanges) { (_, _) in
                categoriesDone = true
                callComplete()
            }
        } else {
            categoriesDone = true
            callComplete()
        }
    }
    
    private func getEntriesSync() -> Date? {
        return self.userDefaults.object(forKey: StoreKeys.entriesSyncTimestamp.rawValue) as? Date
    }
    
    private func recordEntriesSync() {
        self.userDefaults.set(Date(), forKey: StoreKeys.entriesSyncTimestamp.rawValue)
    }
    
    private func getCategoriesSync() -> Date? {
        return self.userDefaults.object(forKey: StoreKeys.categoriesSyncTimestamp.rawValue) as? Date
    }
    
    private func recordCategoriesSync() {
        self.userDefaults.set(Date(), forKey: StoreKeys.categoriesSyncTimestamp.rawValue)
    }
}
