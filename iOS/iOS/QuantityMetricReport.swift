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
    @StateObject var store: OtherAnalyticsStore
    
    var show: Binding<Bool>
    
    var showSeconds: Bool
    var internalShowSeconds: Bool {
        return self.showSeconds && ![TimePeriod.year, TimePeriod.month].contains(self.store.gropuBy)
    }
    var emptyDuration: String {
        return internalShowSeconds ? "00:00:00" : "00:00"
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
                        total: (self.store.totalData[key]?.displayDuration(withSeconds: internalShowSeconds) ?? emptyDuration),
                        description: self.store.title(for: key),
                        items: self.store.categoryData[key]?
                            .map({ (result) -> QuantityMetric.QuantityItem in
                                QuantityMetric.QuantityItem(
                                    name: self.warehouse.getName(for: result.categoryID),
                                    total: result.displayDuration(withSeconds: internalShowSeconds),
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Menu {
                            ForEach(TimePeriod.all()) { timePeriod in
                                Button {
                                    self.store.gropuBy = timePeriod
                                } label: {
                                    if timePeriod == self.store.gropuBy {
                                        Label(timePeriod.display, systemImage: "checkmark")
                                    } else {
                                        Text(timePeriod.display)
                                    }
                                }
                            }
                        } label : {
                            Text("Group By")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }.onReceive(timer, perform: { _ in
            store.refreshAsNeeded()
        })
    }
}
