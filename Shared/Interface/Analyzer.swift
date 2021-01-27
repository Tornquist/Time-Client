//
//  Analyzer.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

public class Analyzer {
    
    private weak var store: Store?
    
    // Internal Cache
    private var closedRanges: [Entry] = []
    private var openRanges: [Entry] = []
    
    private var closedAnalysis: AnalysisCache? = nil {
        didSet {
            self.closedQueryCache = [:]
        }
    }
    private var closedQueryCache: [String: [String : [Analyzer.Result]]] = [:]
    
    // External Types
    
    public enum Operation: String {
        case none
        case calculateTotal
        case calculatePerCategory
    }
    
    public struct Result {
        public var operation: Operation
        public var categoryID: Int?
        public var duration: TimeInterval
        public var open: Bool
        
        public func displayDuration(withSeconds showSeconds: Bool) -> String {
            let time = Int(duration)
            
            let seconds = (time % 60)
            let minutes = (time / 60) % 60
            let hours = (time / 3600)
            
            let timeString = showSeconds
                ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                : String(format: "%02d:%02d", hours, minutes)
            return timeString
        }
        
        private init(operation: Operation, categoryID: Int?, duration: TimeInterval, open: Bool) {
            self.operation = operation
            self.categoryID = categoryID
            self.duration = duration
            self.open = open
        }
        
        public init() {
            self.init(operation: .none, categoryID: nil, duration: 0, open: false)
        }
        
        fileprivate init(overallTotal duration: TimeInterval, open: Bool) {
            self.init(operation: .calculateTotal, categoryID: nil, duration: duration, open: open)
        }
        
        fileprivate init(categoryTotal duration: TimeInterval, forID categoryID: Int, open: Bool) {
            self.init(operation: .calculatePerCategory, categoryID: categoryID, duration: duration, open: open)
        }
    }
    
    // MARK: - Init
    
    init(store: Store) {
        self.store = store

        TimeNotificationGroup.entryDataChanged.notifications.forEach { (notificationType) in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(datasetChanged),
                name: notificationType,
                object: nil
            )
        }

        self.recomputeCache()
    }
    
    @objc private func datasetChanged(notification: NSNotification) {
        self.recomputeCache()
    }
    
    // MARK: - Query
    
    public func evaluate(
        _ timeRange: TimeRange,
        in calendar: Calendar? = nil,
        groupBy: TimePeriod,
        perform operations: [Operation]
    ) -> [String: [Result]] {
        // 1. Identify query range
        let selectedCalendar = calendar ?? Calendar.current
        let from: Date = DateHelper.getStartOf(timeRange, with: Date(), for: selectedCalendar)
        let to: Date? = nil // now

        // 2. Perform query
        return self.evaluate(from: from, to: to, in: selectedCalendar, groupBy: groupBy, perform: operations)
    }
        
    public func evaluate(
        from startDate: Date,
        to endDate: Date?,
        in calendar: Calendar,
        groupBy: TimePeriod,
        perform operations: [Operation]
    ) -> [String: [Result]] {
        // 1. Get closed results (from cache if possible)

        let closedCacheKey = [
            startDate.description.replacingOccurrences(of: " ", with: "_"),
            (endDate?.description ?? "now").replacingOccurrences(of: " ", with: "_"),
            groupBy.rawValue,
            operations.map({ $0.rawValue }).joined(separator: "|")
        ].joined(separator: "-")

        let closedResults: [String : [Result]] = {
            if let cachedClosedResults = self.closedQueryCache[closedCacheKey] {
                return cachedClosedResults
            }
            
            let closedData = self.closedAnalysis?.getGroupedSplits(
                searchingFrom: startDate,
                to: endDate,
                groupingBy: groupBy,
                with: calendar
            ) ?? [:]
            
            let freshClosedResults = self.evaluate(data: closedData, operations: operations)
            
            self.closedQueryCache[closedCacheKey] = freshClosedResults
            
            return freshClosedResults
        }()
        
        // 2. Evaluate open results

        let openPerEntryAnalysis = self.openRanges.map(EntryAnalysis.generate(for:))
        let openAnalysis = AnalysisCache(from: openPerEntryAnalysis)
        let openData = openAnalysis.getGroupedSplits(
            searchingFrom: startDate,
            to: endDate,
            groupingBy: groupBy,
            with: calendar
        )
        let openResults = self.evaluate(data: openData, operations: operations)

        // 3. Merge
        
        let results = self.mergeResults(closedResults, and: openResults)

        // 4. Complete

        return results
    }
    
    // MARK: - Cache Management
    
    private func recomputeCache() {
        guard let store = self.store else {
            self.clearCache()
            return
        }
        
        // 1. Split open and closed ranges
        var closedRanges: [Entry] = []
        var openRanges: [Entry] = []
        store.entries.forEach { (entry) in
            guard entry.type == .range else { return }
            
            if entry.endedAt == nil {
                openRanges.append(entry)
            } else {
                closedRanges.append(entry)
            }
        }
        
        self.closedRanges = closedRanges
        self.openRanges = openRanges
        
        // 2. Analyze all closed entries
        let closedAnalysis = self.closedRanges.map(EntryAnalysis.generate(for:))
        
        // 3. Format and cache closed entries for date-based lookup
        self.closedAnalysis = AnalysisCache(from: closedAnalysis)
    }
    
    private func clearCache() {
        self.closedRanges = []
        self.openRanges = []
        
        self.closedAnalysis = nil
    }
    
    // MARK: - Evaluation
    
    private func evaluate(data: [String : [Split]], operations: [Operation]) -> [String : [Result]] {
        return data.mapValues { (data) -> [Result] in
            var results: [Result] = []
            if operations.contains(.calculateTotal) {
                let totalDuration = data.reduce(0, { $0 + $1.duration })
                let totalOpen = data.reduce(false, { $0 || $1.open })

                results.append(Result(overallTotal: totalDuration, open: totalOpen))
            }
            
            if operations.contains(.calculatePerCategory) {
                let durationByCategory: [Int: TimeInterval] = data.reduce(into: [:]) { (object, record) in
                    object[record.categoryID] = (object[record.categoryID] ?? 0) + record.duration
                }
                let openByCategory: [Int: Bool] = data.reduce(into: [:]) { (object, record) in
                    object[record.categoryID] = (object[record.categoryID] ?? false) || record.open
                }
                
                let categoryResults = durationByCategory.keys.map { (key) -> Result in
                    return Result(categoryTotal: durationByCategory[key]!, forID: key, open: openByCategory[key]!)
                }
                
                results.append(contentsOf: categoryResults)
            }
            
            return results
        }
    }
    
    private func mergeResults(_ setA: [String : [Result]], and setB: [String : [Result]]) -> [String : [Result]] {
        return setA.merging(setB) { (collideA, collideB) -> [Result] in
            var merged: [Result] = []

            let totalA = collideA.first(where: { $0.operation == .calculateTotal })
            let totalB = collideB.first(where: { $0.operation == .calculateTotal })
            
            if let newTotal: TimeInterval = totalA == nil && totalB == nil ? nil : (totalA?.duration ?? 0) + (totalB?.duration ?? 0) {
                let totalOpen: Bool = (totalA?.open ?? false) || (totalB?.open ?? false)
                merged.append(Result(overallTotal: newTotal, open: totalOpen))
            }
            
            var byCategory = collideA.filter({ $0.operation == .calculatePerCategory })
            byCategory.append(contentsOf: collideB.filter({ $0.operation == .calculatePerCategory }))

            var categoryTotals: [Int: TimeInterval] = [:]
            var categoriesOpen: [Int: Bool] = [:]
            byCategory.forEach { (record) in
                // Error. Skip invalid category records
                guard record.categoryID != nil else { return }
                
                categoryTotals[record.categoryID!] = (categoryTotals[record.categoryID!] ?? 0) + record.duration
                categoriesOpen[record.categoryID!] = (categoriesOpen[record.categoryID!] ?? false) || record.open
            }
            
            let newCategoryResults = categoryTotals.keys.map { (key) -> Result in
                return Result(categoryTotal: categoryTotals[key]!, forID: key, open: categoriesOpen[key]!)
            }
            
            merged.append(contentsOf: newCategoryResults)

            return merged
        }
    }
}
