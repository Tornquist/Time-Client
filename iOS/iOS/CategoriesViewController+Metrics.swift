//
//  CategoriesViewController+Metrics.swift
//  iOS
//
//  Created by Nathan Tornquist on 6/22/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import Foundation
import TimeSDK

extension CategoriesViewController {
    
    func getMetricTitle(forDay isDay: Bool) -> String {
        return isDay
            ? NSLocalizedString("Today", comment: "")
            : NSLocalizedString("This Week", comment: "")
    }
    
    func getFormattedMetricData(forDay isDay: Bool, showSeconds: Bool) -> (String, [String : (String, Bool)])? {
        // TODO: Move metric calculation into TimeSDK
        let hasData = isDay ? self.closedDayTimes != nil : self.closedWeekTimes != nil
        guard hasData else {
            return nil
        }
        
        var totalByCategory: [Int: Double] = [:]
        
        (self.openEntries ?? []).forEach { (entry) in
            let duration = Date().timeIntervalSince(entry.startedAt)
            totalByCategory[entry.categoryID] = (totalByCategory[entry.categoryID] ?? 0) + duration
        }

        (isDay ? self.closedDayTimes! : self.closedWeekTimes!).forEach { (record) in
            totalByCategory[record.key] = (totalByCategory[record.key] ?? 0) + record.value
        }
                            
        // Will group all into "unknown" if no category keys exist
        var displayGroups: [String: (Double, Bool)] = [:]
        let activeCategories = Set((self.openEntries ?? []).map({ $0.categoryID }))
        
        totalByCategory.forEach { (record) in
            let categoryID = record.key
            let active = activeCategories.contains(categoryID)
            
            let category = Time.shared.store.categories.first(where: { $0.id == categoryID })
            let name = category?.name
            
            let unknownName = NSLocalizedString("Unknown", comment: "")
            let safeName = name ?? unknownName
            
            let newValue = (displayGroups[safeName]?.0 ?? 0) + record.value
            let newActive = (displayGroups[safeName]?.1 ?? false) || active
            
            displayGroups[safeName] = (newValue, newActive)
        }
        
        let getTimeString = { (time: Int) -> String in
            let seconds = (time % 60)
            let minutes = (time / 60) % 60
            let hours = (time / 3600)
            
            let timeString = showSeconds
                ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                : String(format: "%02d:%02d", hours, minutes)
            return timeString
        }
        
        var displaySplits: [String: (String, Bool)] = [:]
        displayGroups.forEach { (record) in
            let timeString = getTimeString(Int(record.value.0))
            displaySplits[record.key] = (timeString, record.value.1)
        }

        let totalTime = totalByCategory.values.reduce(0, +)
        let ti = Int(totalTime)
        let timeString = getTimeString(ti)
        
        return (timeString, displaySplits)
    }
}
