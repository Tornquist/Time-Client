//
//  DataProcessor.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

class DataProcessor {
    /**
      Will prepare raw entry data for analysis by filtering events and splitting ranges into open and closed groups.
     
     - Parameters:
        - entries: Complete entry data. Can be provided striaght from the store.
     */
    static func filterAndSplitRanges(entries: [Entry]) -> (open: [Entry], closed: [Entry]) {
        var closedRanges: [Entry] = []
        var openRanges: [Entry] = []
        entries.forEach { (entry) in
            guard entry.type == .range else { return }
            
            if entry.endedAt == nil {
                openRanges.append(entry)
            } else {
                closedRanges.append(entry)
            }
        }
        
        return (open: openRanges, closed: closedRanges)
    }
    
    /**
      Used to score or "split" a given entry.
     
     Splitting an entry is calculating the per-day time that the entry is responsible for
     over the dates contained within its total range (start and end).
     
     A entry that is contained within a single calendar day will be responsible for a
     single split (i.e.: no split, one score). Entries that span days are responsible
     for multiple splits.
     
     A closed entry will return a final array of the total relevant scores.
          
     If the entry is still open, the final value in the response will be marked with
     open as true to indicate that the value is live, and will continue to change.

     **Split Details**
     - key: yyyy-MM-dd extracted from the calendar components
     - duration: Total applicable score within the scope of the related key (single day)
     - categoryID: The category of the generating entry
     - open: If the values are final or still active

     - Parameters:
        - entries: Complete entry data. Can be provided striaght from the store.
     */
    static func identifySplits(entry: Entry) -> [Split] {
        // Use starting timezone as reference for chain to resolve any midnight conflicts
        let timezone = DateHelper.getSafeTimezone(identifier: entry.startedAtTimezone)
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        typealias EvaluatedRange = (split: Split, next: Date?)
        let evaluateRange = { (start: Date, end: Date) -> (EvaluatedRange?) in
            let startOfDay = calendar.startOfDay(for: start)
            guard let interval = calendar.dateInterval(of: .day, for: startOfDay) else {
                // Throw Error
                return nil
            }
            
            let dayClosesStreak = end < interval.end
            let attributionEnd = dayClosesStreak ? end : interval.end
            
            let components = calendar.dateComponents([.year, .month, .day], from: start)
            let duration = attributionEnd.timeIntervalSince(start)
            
            // TODO: Make sure will always match yyyy-MM-dd format
            let key = "\(components.year!)-\(String(format: "%02d", components.month!))-\(String(format: "%02d", components.day!))"
            
            let nextStart = dayClosesStreak ? nil : interval.end
            
            let split = Split(for: entry, withKey: key, duration: duration, open: false)
            
            return (split, nextStart)
        }
        
        let startTime = entry.startedAt
        let endTime = entry.endedAt ?? Date()
        let endsOpen = entry.endedAt == nil
        
        let fakeStartSplit = Split(key: "0000-00-00", duration: 0, categoryID: -1, entryID: -1, open: false)
        var testRange: EvaluatedRange = (fakeStartSplit, startTime)

        var splits: [Split] = []
        while (testRange.next != nil) {
            guard let evaluatedRange = evaluateRange(testRange.next!, endTime) else {
                // Day failed. Cannot report
                return []
            }

            splits.append(evaluatedRange.split)
            testRange = evaluatedRange
        }
        
        if endsOpen, let last = splits.popLast() {
            let newLast = Split(from: last, open: true)
            splits.append(newLast)
        }
        
        return splits
    }
}
