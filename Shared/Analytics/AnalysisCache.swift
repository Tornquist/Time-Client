//
//  AnalysisCache.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/10/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

class AnalysisCache {
    
    var dayCache: [String: [Split]] = [:]
    
    init(from data: [EntryAnalysis]) {
        self.dayCache = self.groupSplitsByDay(data)
    }
    
    /**
      Used to fetch all of the cached splits relating to a given time period.
     
     This will return relevant splits grouped under string keys in the format of yyyy-MM-dd.
     
     The keys will refer to the start of the given group range specified by the from, to,
     and groupBy properties.
     
     - Parameters:
        - from: The earliest date to include (Time is ignored)
        - to: The date to stop including data. When nil, searches to present.
        - groupBy: The period to group by
        - calendar: The calendar to use when calculating dates
     
     */
    func getGroupedSplits(searchingFrom from: Date, to: Date?, groupingBy groupBy: TimePeriod, with calendar: Calendar) -> [String: [Split]] {
        let keyGroups = self.identifyKeyGroupsFor(
            stringDates: self.dayCache.keys,
            searchingFrom: from,
            to: to,
            groupingBy: groupBy,
            with: calendar
        )
        
        let groupedRecords = self.getGroupedData(for: keyGroups, in: self.dayCache)
        
        return groupedRecords
    }
    
    // MARK: - Cache Initialization
    
    private func groupSplitsByDay(_ values: [EntryAnalysis]) -> [String: [Split]] {
        var dayAnalysis: [String: [Split]] = [:]
        values.forEach { (entryAnalysis) in
            // Can have multiple entries of a given category per-day
            entryAnalysis.splits.forEach({ (split) in
                let key = "\(split.year)-\(String(format: "%02d", split.month))-\(String(format: "%02d", split.day))"
                dayAnalysis[key] = dayAnalysis[key] ?? []
                dayAnalysis[key]!.append(split)
            }
        )}
        
        return dayAnalysis
    }
    
    // MARK: - Query Support
    
    /**
      This method is used to identify and group dictionary keys that are relevant to a given request.
     
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
        formatter.dateFormat = "yyyy-MM-dd" // matches format set while seeing cache
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

            let keyComponents = key.components(separatedBy: "-")
            guard
                keyComponents.count == 3,
                // The base date must be built in the context of the calendar
                // used to run the query to have stable date lookups. Otherwise
                // the time will be zero (instead of the appropriate start of day
                // time relative to GMT and the final results can shift days.
                let yearValue = Int(keyComponents[0]),
                let monthValue = Int(keyComponents[1]),
                let dayValue = Int(keyComponents[2]),
                let date = calendar.date(from: DateComponents(
                    year: yearValue,
                    month: monthValue,
                    day: dayValue
                ))
            else {
                return nil // Invalid date format. Will be ignored
            }

            let dateComponents = calendar.dateComponents(dateComponentMap[groupBy]!, from: date)
            let parentDate = calendar.date(from: dateComponents)
            let parentKey = formatter.string(from: parentDate!)
            
            return parentKey
        }

        // Build groups with start date as the key, and the related stringDates as the values
        let keyGroups: [String: [String]] = zip(keyStartDates, filteredKeys).reduce(into: [:]) { (acc, next) in
            guard let start = next.0 else { return }
            let value = next.1
            
            acc[start] = acc[start] ?? []
            acc[start]!.append(value)
        }
        
        return keyGroups
    }
    
    /// Apply the result of identifyKeyGroupsFor to the provided data to convert the keys to actual values
    private func getGroupedData(for keyGroups: [String : [String]], in data: [String : [Split]]) -> [String: [Split]] {
        var transformedGroups: [String: [Split]] = [:]
        let groupNames = keyGroups.keys.sorted()
        
        groupNames.forEach { (groupName) in
            guard let groupKeys = keyGroups[groupName], groupKeys.count > 0 else { return }
            
            let allValuesInGroup = groupKeys.flatMap({ data[$0] ?? [] })
            transformedGroups[groupName] = allValuesInGroup
        }
        
        return transformedGroups
    }
}
