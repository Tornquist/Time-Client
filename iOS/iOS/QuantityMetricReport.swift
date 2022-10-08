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
    
    @State var exportLoading: Bool = false
    @State var showExportDialog: Bool = false
    
    var showSeconds: Bool
    var internalShowSeconds: Bool {
        return self.showSeconds && ![TimePeriod.year, TimePeriod.month].contains(self.store.groupBy)
    }
    var emptyDuration: String {
        return internalShowSeconds ? "00:00:00" : "00:00"
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            List(self.store.orderedKeys, id: \.self) { key in
                QuantityMetric(
                    total: (self.store.totalData[key]?.displayDuration(withSeconds: internalShowSeconds) ?? emptyDuration),
                    description: self.store.title(for: key),
                    items: self.store.categoryData[key]?
                        .map({ (result) -> QuantityMetric.QuantityItem in
                            QuantityMetric.QuantityItem(
                                id: result.categoryID ?? self.warehouse.getName(for: result.categoryID).hashValue,
                                name: self.warehouse.getName(for: result.categoryID),
                                total: result.displayDurationAndOrEvents(withSeconds: internalShowSeconds),
                                active: result.open
                            )
                        }) ?? []
                )
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
                                    self.store.groupBy = timePeriod
                                } label: {
                                    if timePeriod == self.store.groupBy {
                                        Label(timePeriod.display, systemImage: "checkmark")
                                    } else {
                                        Text(timePeriod.display)
                                    }
                                }
                            }
                        } label : {
                            Text("Group By")
                        }
                        Button {
                            self.store.includeEmpty = !self.store.includeEmpty
                        } label: {
                            if self.store.includeEmpty {
                                Label("Include Empty", systemImage: "checkmark")
                            } else {
                                Text("Include Empty")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.store.buildExport(
                            doneLoading: self.$exportLoading,
                            readyForUI: self.$showExportDialog
                        )
                        self.exportLoading = true
                    } label: {
                        if self.exportLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }.onReceive(timer, perform: { _ in
            store.refreshAsNeeded()
        })
        .fileExporter(
            isPresented: self.$showExportDialog,
            document: self.store.exportDocument,
            contentType: .plainText,
            defaultFilename: "\(self.store.inDateFormatter.string(from: Date()))_time_\(self.store.groupBy.rawValue)_export.csv"
        ) { _ in }
    }
}
