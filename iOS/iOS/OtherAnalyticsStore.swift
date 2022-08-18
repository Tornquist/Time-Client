//
//  OtherAnalyticsStore.swift
//  iOS
//
//  Created by Nathan Tornquist on 8/6/22.
//  Copyright © 2022 nathantornquist. All rights reserved.
//

import Foundation
import Combine
import TimeSDK
import WidgetKit

class OtherAnalyticsStore: ObservableObject {

    @Published var warehouse: Warehouse
    
    private let storeGroupByKey = "other-analytics-store-group-by"
    private let storeIncludeEmptyKey = "other-analytics-store-include-empty"
    @Published var gropuBy: TimePeriod {
        didSet {
            Mainify {
                self.calculateMetrics()
                // Persist preference to store
                UserDefaults().set(self.gropuBy.rawValue, forKey: self.storeGroupByKey)
            }
        }
    }
    @Published var includeEmpty: Bool {
        didSet {
            Mainify {
                self.calculateMetrics()
                // Persist preference to store
                UserDefaults().set(self.includeEmpty, forKey: self.storeIncludeEmptyKey)
            }
        }
    }
    
    var inDateFormatter: DateFormatter = DateFormatter()
    var dayDateFormatter: DateFormatter = DateFormatter()
    var weekDateFormatter: DateFormatter = DateFormatter()
    var monthDateFormatter: DateFormatter = DateFormatter()
    var yearDateFormatter: DateFormatter = DateFormatter()
    
    @Published var orderedKeys: [String] = []
    @Published var totalData: [String : Analyzer.Result] = [:]
    @Published var categoryData: [String : [Analyzer.Result]] = [:]
    
    var cancellables = [AnyCancellable]()
    
    init(for warehouse: Warehouse) {
        // Load groupBy first for single-pass analytics
        self.gropuBy = TimePeriod(
            rawValue: UserDefaults().string(forKey: self.storeGroupByKey) ?? ""
        ) ?? .week
        
        // Load includeEmpty first for single-pass analytics
        self.includeEmpty = UserDefaults().bool(forKey: self.storeIncludeEmptyKey)
        
        self.warehouse = warehouse

        let c = warehouse.objectWillChange.sink { self.objectWillChange.send() }
        self.cancellables.append(c)
        
        self.configureDateFormatters()
        
        self.registerNotifications()
        self.calculateMetrics()
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .TimeBackgroundStoreUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .TimeEntryStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .TimeEntryStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .TimeEntryRecorded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .TimeEntryModified, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .TimeEntryDeleted, object: nil)
    }
    
    @objc private func handleNotification(_ notification:Notification) {
        self.calculateMetrics()
    }
    
    private func configureDateFormatters() {
        self.inDateFormatter.dateFormat = "yyyy-MM-dd"
        self.inDateFormatter.timeZone = TimeZone.current // Sync with analyzer
        self.inDateFormatter.locale = Locale.current // Sync with analyzer
        
        self.dayDateFormatter.dateFormat = "MMMM d, yyyy"
        self.dayDateFormatter.timeZone = TimeZone.current
        self.dayDateFormatter.locale = Locale.current
        
        self.weekDateFormatter.dateFormat = "MMM d, yyyy"
        self.weekDateFormatter.timeZone = TimeZone.current
        self.weekDateFormatter.locale = Locale.current
        
        self.monthDateFormatter.dateFormat = "MMMM yyyy"
        self.monthDateFormatter.timeZone = TimeZone.current
        self.monthDateFormatter.locale = Locale.current
        
        self.yearDateFormatter.dateFormat = "yyyy"
        self.yearDateFormatter.timeZone = TimeZone.current
        self.yearDateFormatter.locale = Locale.current
    }
    
    func title(for key: String) -> String {
        guard let date = self.inDateFormatter.date(from: key) else {
            return key
        }
        
        switch self.gropuBy {
        case .day:
            return self.dayDateFormatter.string(from: date)
        case .week:
            return "Week of " + self.weekDateFormatter.string(from: date)
        case .month:
            return self.monthDateFormatter.string(from: date)
        case .year:
            return self.yearDateFormatter.string(from: date)
        }
        
    }
    
    // MARK: - Metrics
    
    func refreshAsNeeded() {
        guard self.warehouse.openCategoryIDs.count > 0 else { return }
        
        self.calculateMetrics()
    }
    
    private func calculateMetrics() {
        let updatedData = Time.shared.analyzer.evaluateAll(
            gropuBy: self.gropuBy, perform: [.calculateTotal, .calculatePerCategory], includeEmpty: self.includeEmpty
        )
        
        let startingKeys = self.orderedKeys
        let orderedKeys = updatedData.keys.sorted().reversed()
        let removedData = Array(Set(startingKeys).subtracting(Set(orderedKeys)))
        
        orderedKeys.forEach { key in
            guard let data = updatedData[key] else { return }
            
            let total = data.first(where: { $0.operation == .calculateTotal })
            let categories = data.filter({ $0.operation == .calculatePerCategory })
                .sorted(by: sortAnalyzerResults)
            
            Mainify {
                self.totalData[key] = total
                self.categoryData[key] = categories
             }
        }
        
        Mainify {
            removedData.forEach { key in
                self.totalData.removeValue(forKey: key)
                self.categoryData.removeValue(forKey: key)
            }
            
            self.orderedKeys = Array(orderedKeys)
        }
    }
    
    private func sortAnalyzerResults(a: Analyzer.Result, b: Analyzer.Result) -> Bool {
        let aName = self.warehouse.getName(for: a.categoryID)
        let bName = self.warehouse.getName(for: b.categoryID)
        return aName < bName
    }
}
