//
//  QuantityMetricReport.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/8/22.
//  Copyright © 2022 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct QuantityMetricReport: View {
    @EnvironmentObject var warehouse: Warehouse
    @ObservedObject var store: OtherAnalyticsStore
    
    var show: Binding<Bool>
    
    var showSeconds: Bool
    var emptyDuration: String {
        return showSeconds ? "00:00:00" : "00:00"
    }
    
    @State private var data: [String : [Analyzer.Result]] = Time.shared.analyzer.evaluateAll(
        gropuBy: .week, perform: [.calculateTotal, .calculatePerCategory]
    )
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.store.orderedKeys, id: \.self) { key in
                    QuantityMetric(
                        total: (self.store.totalData[key]?.displayDuration(withSeconds: showSeconds) ?? emptyDuration),
                        description: "Week of \(key)",
                        items: self.store.categoryData[key]?
                            .map({ (result) -> QuantityMetric.QuantityItem in
                                QuantityMetric.QuantityItem(
                                    name: self.warehouse.getName(for: result.categoryID),
                                    total: result.displayDuration(withSeconds: showSeconds),
                                    active: result.open
                                )
                            }) ?? []
                    )
                }
                .listRowInsets(EdgeInsets())
                .padding(EdgeInsets())
            }
            .navigationTitle("Metrics")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        self.show.wrappedValue = false
                    }
                }
            }
        }.onReceive(timer, perform: { _ in
            store.refreshAsNeeded()
        })
    }
    
    func sortAnalyzerResults(a: Analyzer.Result, b: Analyzer.Result) -> Bool {
        let aName = self.warehouse.getName(for: a.categoryID)
        let bName = self.warehouse.getName(for: b.categoryID)
        return aName < bName
    }
}
