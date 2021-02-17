//
//  AnalyticsStore.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/16/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation
import Combine
import TimeSDK
import WidgetKit

class AnalyticsStore: ObservableObject {

    @Published var warehouse: Warehouse
    
    @Published var dayTotal: Analyzer.Result? = nil
    @Published var dayCategories: [Analyzer.Result] = []
    
    @Published var weekTotal: Analyzer.Result? = nil
    @Published var weekCategories: [Analyzer.Result] = []

    var secondUpdateTimer: Timer? = nil
    
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
            }
        } else {
            Mainify {
                self.dayTotal = nil
                self.dayCategories = []
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
        let aName = self.warehouse.getName(for: a.categoryID)
        let bName = self.warehouse.getName(for: b.categoryID)
        return aName < bName
    }
}
