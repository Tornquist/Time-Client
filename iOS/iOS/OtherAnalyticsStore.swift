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
import SwiftUI // For Binding

class OtherAnalyticsStore: ObservableObject {

    @Published var warehouse: Warehouse
    
    private let storeGroupByKey = "other-analytics-store-group-by"
    private let storeIncludeEmptyKey = "other-analytics-store-include-empty"
    @Published var groupBy: TimePeriod {
        didSet {
            self.calculateMetrics()
            // Persist preference to store
            UserDefaults().set(self.groupBy.rawValue, forKey: self.storeGroupByKey)
        }
    }
    @Published var includeEmpty: Bool {
        didSet {
            self.calculateMetrics()
            // Persist preference to store
            UserDefaults().set(self.includeEmpty, forKey: self.storeIncludeEmptyKey)
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
    
    @Published var exportDocument: ReportDocument? = nil
    
    var cancellables = [AnyCancellable]()
    
    init(for warehouse: Warehouse) {
        // Load groupBy first for single-pass analytics
        self.groupBy = TimePeriod(
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
        
        switch self.groupBy {
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

        DispatchQueue.global(qos: .background).async {
            self.calculateMetrics()
        }
    }
    
    private func calculateMetrics() {
        let updatedData = Time.shared.analyzer.evaluateAll(
            gropuBy: self.groupBy, perform: [.calculateTotal, .calculatePerCategory], includeEmpty: self.includeEmpty
        )
        
        let startingKeys = self.orderedKeys
        let orderedKeys = updatedData.keys.sorted().reversed()
        let removedData = Array(Set(startingKeys).subtracting(Set(orderedKeys)))
        
        orderedKeys.forEach { key in
            guard let data = updatedData[key] else { return }
            
            let total = data.first(where: { $0.operation == .calculateTotal })
            let categories = data.filter({ $0.operation == .calculatePerCategory })
                .sorted(by: sortAnalyzerResults)
            
            if self.totalData[key] != total {
                Mainify {
                    self.totalData[key] = total
                }
            }
            if self.categoryData[key] != categories {
                Mainify {
                    self.categoryData[key] = categories
                }
            }
        }
        
        
        removedData.forEach { key in
            Mainify {
                self.totalData.removeValue(forKey: key)
                self.categoryData.removeValue(forKey: key)
            }
        }
            
        let newArray: [String] = Array(orderedKeys)
        if self.orderedKeys != newArray {
            Mainify {
                self.orderedKeys = newArray
            }
        }
    }
    
    private func sortAnalyzerResults(a: Analyzer.Result, b: Analyzer.Result) -> Bool {
        let aName = self.warehouse.getName(for: a.categoryID)
        let bName = self.warehouse.getName(for: b.categoryID)
        return aName < bName
    }
    
    // MARK: - Export Results
    
    func buildExport(
        doneLoading: Binding<Bool>,
        readyForUI: Binding<Bool>
    ) {
        // Rebuild File
        DispatchQueue.global(qos: .background).async {
            var rows = ["Date, Type, Path, Name, Duration (s), Duration (h)"]
            self.orderedKeys.forEach { key in
                // Append total (without path or name)
                let durationSeconds = self.totalData[key]?.duration ?? 0
                let durationHours = durationSeconds / 60 / 60
                rows.append("\(key), Total, , ,\(durationSeconds), \(durationHours)")
                
                var nameCache: [Int: String] = [:]
                var pathCache: [Int: String] = [:]
                
                // Append categories
                self.categoryData[key]?.forEach({ result in
                    var name = nameCache[result.categoryID ?? -1]
                    if name == nil && result.categoryID != nil {
                        name = self.warehouse.getName(for: result.categoryID)
                        nameCache[result.categoryID!] = name
                    }
                    var path = pathCache[result.categoryID ?? -1]
                    if path == nil && result.categoryID != nil {
                        path = self.warehouse.getParentHierarchyName(for: result.categoryID)
                        pathCache[result.categoryID!] = path
                    }
                    
                    let safeName = (name?.contains(",") ?? false) ? "\"\(name!)\"" : (name ?? "")
                    let safePath = (path?.contains(",") ?? false) ? "\"\(path!)\"" : (path ?? "")
                    
                    rows.append("\(key), Category, \(safePath), \(safeName), \(result.duration), \(result.duration / 60 / 60)")
                })
            }
            
            let file = rows.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.exportDocument = ReportDocument(message: file)
                
                doneLoading.wrappedValue = false
                readyForUI.wrappedValue = true
            }
        }
    }
}
