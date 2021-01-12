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
        let totalData = isDay ? self.dayTotal : self.weekTotal
        let totalTime = (totalData ?? Analyzer.Result()).displayDuration(withSeconds: showSeconds)
        
        let categoryData = isDay ? self.dayCategories : self.weekCategories
        let categoryDisplaySplits: [String: (String, Bool)] = categoryData.map({ (record) -> (String, String, Bool) in
            let category = Time.shared.store.categories.first(where: { $0.id == record.categoryID })
            let categoryName = category?.name ?? NSLocalizedString("Unknown", comment: "")
            
            let displayDuration = record.displayDuration(withSeconds: showSeconds)
            let active = record.open
            
            return (categoryName, displayDuration, active)
        }).reduce(into: [:]) { (store, record) in
            store[record.0] = (record.1, record.2)
        }
        
        return (totalTime, categoryDisplaySplits)
    }
}
