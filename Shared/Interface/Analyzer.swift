//
//  Analyzer.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

public class Analyzer {
    
    weak var store: Store?
    
    // Internal Cache
    var closedRanges: [Entry] = []
    var openRanges: [Entry] = []
    
    var closedAnalysis: [EntryAnalysis] = []
    var closedAnalysisSplitsByDay: [String: [Split]] = [:]
    
    // External Types
    
    public enum Operation {
        case calculateOverallTotal
        case calculateCategoryTotals
    }
    
    public struct Result {
        var operation: Operation
        var categoryID: Int?
        var duration: TimeInterval
        var open: Bool
        
        private init(operation: Operation, categoryID: Int?, duration: TimeInterval, open: Bool) {
            self.operation = operation
            self.categoryID = categoryID
            self.duration = duration
            self.open = open
        }
        
        fileprivate init(overallTotal duration: TimeInterval, open: Bool) {
            self.init(operation: .calculateOverallTotal, categoryID: nil, duration: duration, open: open)
        }
        
        fileprivate init(categoryTotal duration: TimeInterval, forID categoryID: Int, open: Bool) {
            self.init(operation: .calculateCategoryTotals, categoryID: categoryID, duration: duration, open: open)
        }
    }
    
    // Internal Types
    
    /// Results paired with the entry used to generate them
    struct EntryAnalysis {
        var source: Entry
        var splits: [Split]
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
    
    public func evaluate(_ timeRange: TimeRange, groupBy: TimePeriod, perform operations: [Operation]) -> [String: [Result]] {
        // 1. Identify query range
        let calendar = Calendar.current
        let from: Date = DateHelper.getStartOf(timeRange, for: calendar)
        let to: Date? = nil // now
        
        // 2. Evaluate open results
        let openAnalysis = self.openRanges.map(self.analyze)
        let openAnalysisSplitsByDay = self.groupSplitsByDay(openAnalysis)
        
        // 3. Grab relevant records
        let closedAnalysisDays = self.closedAnalysisSplitsByDay.keys
        let openAnalysisDays = openAnalysisSplitsByDay.keys

        let closedKeyGroups = self.identifyKeyGroupsFor(
            stringDates: closedAnalysisDays,
            searchingFrom: from,
            to: to,
            groupingBy: groupBy,
            with: calendar
        )
        
        let openKeyGroups = self.identifyKeyGroupsFor(
            stringDates: openAnalysisDays,
            searchingFrom: from,
            to: to,
            groupingBy: groupBy,
            with: calendar
        )

        let closedData = self.getQueryData(for: closedKeyGroups, in: self.closedAnalysisSplitsByDay)
        let openData = self.getQueryData(for: openKeyGroups, in: openAnalysisSplitsByDay)

        // 4. Evaluate
        
        let closedResults = self.evaluate(data: closedData, operations: operations)
        let openResults = self.evaluate(data: openData, operations: operations)

        // 4. Merge
        
        let results = self.mergeResults(closedResults, and: openResults)

        // 5. Complete

        return results
    }
    
    // MARK: - Cache Management
    
    private func recomputeCache() {
        guard let store = self.store else {
            self.clearCache()
            return
        }
        
        // 1. Split open and closed ranges
        let splitRanges = DataProcessor.filterAndSplitRanges(entries: store.entries)
        self.closedRanges = splitRanges.closed
        self.openRanges = splitRanges.open
        
        // 2. Analyze all closed entries
        self.closedAnalysis = self.closedRanges.map(self.analyze)
        
        // 3. Format and cache closed entries for date-based lookup
        self.closedAnalysisSplitsByDay = self.groupSplitsByDay(self.closedAnalysis)
    }
    
    private func clearCache() {
        self.closedRanges = []
        self.openRanges = []
        
        self.closedAnalysis = []
        self.closedAnalysisSplitsByDay = [:]
    }
    
    // MARK: - Data Transformation
    
    /// Apply all analysis actions to a provided entry
    private func analyze(entry: Entry) -> EntryAnalysis {
        let splits = DataProcessor.identifySplits(entry: entry)
        return EntryAnalysis(source: entry, splits: splits)
    }
    
    /// Reformat analysis to date-based lists that can be quickly queried.
    private func groupSplitsByDay(_ values: [EntryAnalysis]) -> [String: [Split]] {
        var dayAnalysis: [String: [Split]] = [:]
        values.forEach { (entryAnalysis) in
            // Can have multiple entries of a given category per-day
            entryAnalysis.splits.forEach({ (split) in
                dayAnalysis[split.key] = dayAnalysis[split.key] ?? []
                dayAnalysis[split.key]!.append(split)
            }
        )}
        
        return dayAnalysis
    }
    
    /**
      This method is used to identify and group dictionary keys that are relevant to a given request.
     
     The keys must be provided in yyyy-MM-dd format and the grouped results will be
     organized based on the start of a given time period. It is easiest to just to provide
     the keys generated by `groupSplitsByDay`. If a key is not in the proper format
     the results are undefined. Filters are applied using sorted string comparison.
     
     When grouping by day, the results will be 1-1, with a day having a single value in
     the resulting array (itself).
     
     When grouping by week, the results will have all relevant keys for the appropriate
     week in the resulting array.

     - Parameters:
        - stringDates: The date keys to analyze in yyyy-MM-dd format
        - searchingFrom: The earliest date to include (Time is ignored)
        - to: The date to stop including data. When nil, searches to present.
        - groupBy: The period to group by
        - calendar: The calendar to use when calculating dates
     
     */
    private func identifyKeyGroupsFor(stringDates: Dictionary<String, [Split]>.Keys, searchingFrom from: Date, to: Date?, groupingBy groupBy: TimePeriod, with calendar: Calendar) -> [String: [String]] {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar

        // Identify values in range
        let startKey = formatter.string(from: from)
        let endKey = to != nil ? formatter.string(from: to!) : nil

        let filteredKeys = stringDates
            .filter({ $0 >= startKey })
            .filter({ endKey != nil ? $0 < endKey! : true })
        
        // Identify the start date of every key based on the groupBy type
        let dateComponentMap: [TimePeriod: Set<Calendar.Component>] = [
            .day: [.year, .month, .day], // will not be used because of guard
            .week: [.yearForWeekOfYear, .weekOfYear],
            .month: [.year, .month],
            .year: [.year]
        ]

        let keyStartDates = filteredKeys.map { (key) -> String? in
            guard groupBy != .day else { return key }

            guard let date = formatter.date(from: key) else {
                return nil // Invalid date format. Will be ignored
            }
            let dateComponents = calendar.dateComponents(dateComponentMap[groupBy]!, from: date)
            let parentDate = calendar.date(from: dateComponents)
            let parentKey = formatter.string(from: parentDate!)
            
            return parentKey
        }
        
        // Build groups with start date as the key, and the related stringDates as the values
        let keyGroups: [String: [String]] = zip(filteredKeys, keyStartDates).reduce(into: [:]) { (acc, next) in
            let key = next.0
            guard let value = next.1 else { return }
            
            acc[key] = acc[key] ?? []
            acc[key]!.append(value)
        }
        
        return keyGroups
    }
    
    /// Apply the result of identifyKeyGroupsFor to the provided data to convert the keys to actual values
    private func getQueryData(for keyGroups: [String : [String]], in data: [String : [Split]]) -> [String: [Split]] {
        var transformedGroups: [String: [Split]] = [:]
        let groupNames = keyGroups.keys.sorted()
        
        groupNames.forEach { (groupName) in
            guard let groupKeys = keyGroups[groupName], groupKeys.count > 0 else { return }
            
            let allValuesInGroup = groupKeys.flatMap({ data[$0] ?? [] })
            transformedGroups[groupName] = allValuesInGroup
        }
        
        return transformedGroups
    }
    
    // MARK: - Evaluation
    
    private func evaluate(data: [String : [Split]], operations: [Operation]) -> [String : [Result]] {
        return data.mapValues { (data) -> [Result] in
            var results: [Result] = []
            if operations.contains(.calculateOverallTotal) {
                let totalDuration = data.reduce(0, { $0 + $1.duration })
                let totalOpen = data.reduce(false, { $0 || $1.open })

                results.append(Result(overallTotal: totalDuration, open: totalOpen))
            }
            
            if operations.contains(.calculateCategoryTotals) {
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

            let totalA = collideA.first(where: { $0.operation == .calculateOverallTotal })
            let totalB = collideB.first(where: { $0.operation == .calculateOverallTotal })
            
            if let newTotal: TimeInterval = totalA == nil && totalB == nil ? nil : (totalA?.duration ?? 0) + (totalB?.duration ?? 0) {
                let totalOpen: Bool = (totalA?.open ?? false) || (totalB?.open ?? false)
                merged.append(Result(overallTotal: newTotal, open: totalOpen))
            }
            
            var byCategory = collideA.filter({ $0.operation == .calculateOverallTotal })
            byCategory.append(contentsOf: collideB.filter({ $0.operation == .calculateOverallTotal }))
                    
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
