//
//  MetricSection.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct MetricSection: View {
    @EnvironmentObject var warehouse: Warehouse
    
    var showSeconds: Bool
    var emptyDuration: String {
        return showSeconds ? "00:00:00" : "00:00"
    }
        
    var body: some View {
        QuantityMetric(
            total: self.warehouse.dayTotal?.displayDuration(withSeconds: showSeconds) ?? emptyDuration,
            description: "Today",
            items: self.warehouse.dayCategories.map({ (result) -> QuantityMetric.QuantityItem in
                QuantityMetric.QuantityItem(
                    name: self.warehouse.getName(for: result.categoryID),
                    total: result.displayDuration(withSeconds: showSeconds),
                    active: result.open
                )
            })
        )
        QuantityMetric(
            total: self.warehouse.weekTotal?.displayDuration(withSeconds: showSeconds) ?? emptyDuration,
            description: "This Week",
            items: self.warehouse.weekCategories.map({ (result) -> QuantityMetric.QuantityItem in
                QuantityMetric.QuantityItem(
                    name: self.warehouse.getName(for: result.categoryID),
                    total: result.displayDuration(withSeconds: showSeconds),
                    active: result.open
                )
            })
        )
    }
}
