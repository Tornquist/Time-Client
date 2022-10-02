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
    @StateObject var store: AnalyticsStore
    
    var showSeconds: Bool
    var emptyDuration: String {
        return showSeconds ? "00:00:00" : "00:00"
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
    var body: some View {
        Group {
            QuantityMetric(
                total: store.dayTotal?.displayDuration(withSeconds: showSeconds) ?? emptyDuration,
                description: "Today",
                items: store.dayCategories.map({ (result) -> QuantityMetric.QuantityItem in
                    QuantityMetric.QuantityItem(
                        id: result.categoryID ?? self.warehouse.getName(for: result.categoryID).hashValue,
                        name: self.warehouse.getName(for: result.categoryID),
                        total: result.displayDuration(withSeconds: showSeconds),
                        active: result.open
                    )
                })
            )
            QuantityMetric(
                total: store.weekTotal?.displayDuration(withSeconds: showSeconds) ?? emptyDuration,
                description: "This Week",
                items: store.weekCategories.map({ (result) -> QuantityMetric.QuantityItem in
                    QuantityMetric.QuantityItem(
                        id: result.categoryID ?? self.warehouse.getName(for: result.categoryID).hashValue,
                        name: self.warehouse.getName(for: result.categoryID),
                        total: result.displayDuration(withSeconds: showSeconds),
                        active: result.open
                    )
                })
            )
        }.onReceive(timer, perform: { _ in
            store.refreshAsNeeded()
        })
    }
}
