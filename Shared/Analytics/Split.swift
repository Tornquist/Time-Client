//
//  Split.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

struct Split {
    var year: Int
    var month: Int
    var day: Int
    
    var duration: TimeInterval
    var categoryID: Int
    var entryID: Int
    var open: Bool
    
    init(year: Int, month: Int, day: Int, duration: TimeInterval, categoryID: Int, entryID: Int, open: Bool) {
        self.year = year
        self.month = month
        self.day = day
        
        self.duration = duration
        self.categoryID = categoryID
        self.entryID = entryID
        self.open = open
    }
    
    init(for entry: Entry, year: Int, month: Int, day: Int, duration: TimeInterval, open: Bool) {
        self.init(year: year, month: month, day: day, duration: duration, categoryID: entry.categoryID, entryID: entry.id, open: open)
    }
    
    init(from base: Split, duration: TimeInterval? = nil, categoryID: Int? = nil, entryID: Int? = nil, open: Bool? = nil) {
        self.init(
            year: base.year,
            month: base.month,
            day: base.day,
            duration: duration ?? base.duration,
            categoryID: categoryID ?? base.categoryID,
            entryID: entryID ?? base.entryID,
            open: open ?? base.open
        )
    }
    
    /**
      Used to generate all applicable splits from a given entry
     
     Splitting an entry is calculating the per-day time that the entry is responsible for
     over the dates contained within its total range (start and end).
     
     A entry that is contained within a single calendar day will be responsible for a
     single split (i.e.: no split, one score). Entries that span days are responsible
     for multiple splits.
     
     A closed entry will return a final array of the total relevant scores.
          
     If the entry is still open, the final value in the response will be marked with
     open as true to indicate that the value is live, and will continue to change.

     **Split Details**
     - duration: Total applicable score within the scope of the related key (single day)
     - categoryID: The category of the generating entry
     - open: If the values are final or still active

     - Parameters:
        - entries: Complete entry data. Can be provided striaght from the store.
     */
    static func identify(for entry: Entry) -> [Split] {
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
            
            let split = Split(
                for: entry,
                year: components.year!,
                month: components.month!,
                day: components.day!,
                duration: duration,
                open: false
            )
            
            let nextStart = dayClosesStreak ? nil : interval.end
            return (split, nextStart)
        }
        
        let startTime = entry.startedAt
        let endTime = entry.endedAt ?? Date()
        let endsOpen = entry.endedAt == nil
        
        let fakeStartSplit = Split(year: 0, month: 0, day: 0, duration: 0, categoryID: -1, entryID: -1, open: false)
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
