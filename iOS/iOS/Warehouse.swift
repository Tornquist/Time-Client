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
    
    @Published var trees: [CategoryTree] = []
    
    @Published var recentCategories: [CategoryTree] = []
    @Published var recentCategoryIsRange: [Bool] = []
    
    @Published var openCategoryIDs: [Int] = []
    
    @Published var dayTotal: Analyzer.Result? = nil
    @Published var dayCategories: [Analyzer.Result] = []
    
    @Published var weekTotal: Analyzer.Result? = nil
    @Published var weekCategories: [Analyzer.Result] = []

    var secondUpdateTimer: Timer? = nil
    @Published var isRefreshing: Bool = false
    
    var cancellables = [AnyCancellable]()
        
    init(trees: [CategoryTree]) {
        self.trees = trees
        self.trees.forEach { (tree) in
            let c = tree.objectWillChange.sink { self.objectWillChange.send() }
            self.cancellables.append(c)
        }
    }
    
    convenience init(for time: Time) {
        let trees = Time.shared.store.categoryTrees.values.sorted { (a, b) -> Bool in
            return a.node.accountID < b.node.accountID
        }
        
        self.init(trees: trees)
        
        self.time = time

        self.registerNotifications()
        self.loadData()
    }
    
    public func refreshAsNeeded() {
        self.refreshMetricsAsNeeded()
    }
    
    // MARK: - Display Helpers
    
    func getName(for categoryID: Int?) -> String {
        let category = self.time?.store.categories.first(where: { $0.id == categoryID })
        let categoryName = category?.name ?? NSLocalizedString("Unknown", comment: "")
        return categoryName
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
    
    // MARK: - Refresh All
    
    func loadData(refresh: Bool = false) {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        
        var categoriesDone = false
        var entriesDone = false
        
        let completion: (Error?) -> Void = { error in
            DispatchQueue.main.async {
                if categoriesDone && entriesDone {
                    self.isRefreshing = false
                }
            }
            self.refreshAllCalculations()
        }
        
        let networkMode: Store.NetworkMode = refresh ? .refreshAll : .asNeeded
        time?.store.getCategories(networkMode) { (categories, error) in categoriesDone = true; completion(error) }
        time?.store.getEntries(networkMode) { (entries, error) in entriesDone = true; completion(error) }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundUpdate(_:)), name: .TimeBackgroundStoreUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryRecorded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryModified, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryDeleted, object: nil)
    }

    @objc private func handleBackgroundUpdate(_ notification:Notification) {
        self.calculateMetrics()
        self.calculateMetrics()
    }
    
    @objc private func handleEntryNotification(_ notification:Notification) {
        self.refreshAllCalculations()
        self.refreshAllCalculations()
    }
    
    private func refreshAllCalculations() {
        self.calculateRecentCategories()
        self.calculateMetrics()
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
    
    // MARK: - Metrics
    
    private func refreshMetricsAsNeeded() {
        guard self.openCategoryIDs.count > 0 else { return }
        
        self.calculateMetrics()
    }
    
    private func calculateMetrics() {
        let dayAnalysisResult = Time.shared.analyzer.evaluate(
            TimeRange(current: .day),
            groupBy: .day,
            perform: [.calculateTotal, .calculatePerCategory]
        )
        
        if dayAnalysisResult.keys.count == 1,
           let dayAnalysis = dayAnalysisResult.values.first,
           let dayTotal = dayAnalysis.first(where: { $0.operation == .calculateTotal }) {
            let dayCategories = dayAnalysis.filter({ $0.operation == .calculatePerCategory })
                .sorted(by: sortAnalyzerResults)
            
            Mainify {
                self.dayTotal = dayTotal
                self.dayCategories = dayCategories
                
                self.openCategoryIDs = self.dayCategories.filter({ $0.open == true }).compactMap({ $0.categoryID })
            }
        } else {
            Mainify {
                self.dayTotal = nil
                self.dayCategories = []
                
                self.openCategoryIDs = []
            }
        }
        
        let weekAnalysisResult = Time.shared.analyzer.evaluate(
            TimeRange(current: .week),
            groupBy: .week,
            perform: [.calculateTotal, .calculatePerCategory]
        )
        
        if weekAnalysisResult.keys.count == 1,
           let weekAnalysis = weekAnalysisResult.values.first,
           let weekTotal = weekAnalysis.first(where: { $0.operation == .calculateTotal }) {
            let weekCategories = weekAnalysis.filter({ $0.operation == .calculatePerCategory })
                .sorted(by: sortAnalyzerResults)
            
            Mainify {
                self.weekTotal = weekTotal
                self.weekCategories = weekCategories
            }
        } else {
            Mainify {
                self.weekTotal = nil
                self.weekCategories = []
            }
        }
    }
    
    private func sortAnalyzerResults(a: Analyzer.Result, b: Analyzer.Result) -> Bool {
        let aName = self.getName(for: a.categoryID)
        let bName = self.getName(for: b.categoryID)
        return aName < bName
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
        let store = Warehouse(trees: trees)
        
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