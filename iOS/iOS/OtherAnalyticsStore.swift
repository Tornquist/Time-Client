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
    
    @Published var orderedKeys: [String] = []
    @Published var totalData: [String : Analyzer.Result] = [:]
    @Published var categoryData: [String : [Analyzer.Result]] = [:]
    
    var cancellables = [AnyCancellable]()
    
    init(for warehouse: Warehouse) {
        self.warehouse = warehouse
        
        let c = warehouse.objectWillChange.sink { self.objectWillChange.send() }
        self.cancellables.append(c)
        
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
    
    // MARK: - Metrics
    
    func refreshAsNeeded() {
        guard self.warehouse.openCategoryIDs.count > 0 else { return }
        
        self.calculateMetrics()
    }
    
    private func calculateMetrics() {
        let updatedData = Time.shared.analyzer.evaluateAll(
            gropuBy: .week, perform: [.calculateTotal, .calculatePerCategory]
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
