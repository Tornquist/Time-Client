//
//  CategoryReport.swift
//  iOS
//
//  Created by Nathan Tornquist on 10/2/22.
//  Copyright © 2022 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK
import Charts

struct CategoryReport: View {
    @EnvironmentObject var warehouse: Warehouse
    @StateObject var store: CategoryReportStore
    
    @Binding var show: Bool
    
    // TODO: Remove need to keep init in sync with store
    @State var rangeSelection: CategoryReportStore.RangeOption = .month
    @State var groupBySelection: TimePeriod = .day
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if store.graphData.count > 0 {
                        Chart {
                            ForEach(self.store.graphData) { entry in
                                BarMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Duration", entry.duration)
                                )
                                .foregroundStyle(by: .value("Type", entry.category))
                            }
                        }
                        .chartXAxis {
                            if rangeSelection == .all {
                                AxisMarks(values: .stride(by: .year))
                            } else if rangeSelection == .year {
                                AxisMarks(values: .stride(by: .month))
                            } else {
                                AxisMarks(values: .stride(by: .weekOfYear))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                AxisGridLine()
                                
                                let formatter: DateComponentsFormatter = {
                                    let formatter = DateComponentsFormatter()
                                    formatter.unitsStyle = .abbreviated
                                    formatter.allowedUnits = [.hour]
                                    return formatter
                                }()
                                
                                if let timeInterval = value.as(TimeInterval.self), let formatted = formatter.string(from: timeInterval) {
                                    AxisValueLabel(formatted)
                                }
                            }
                        }
                        .frame(height: 300)
                    } else {
                        HStack {
                            Spacer()
                            Text("No data")
                                .italic()
                                .foregroundColor(Color(UIColor.placeholderText))
                            Spacer()
                        }
                    }
                        
                    Picker("Range", selection: $rangeSelection) {
                        Text("All").tag(CategoryReportStore.RangeOption.all)
                        Text("Year").tag(CategoryReportStore.RangeOption.year)
                        Text("Month").tag(CategoryReportStore.RangeOption.month)
                        Text("Week").tag(CategoryReportStore.RangeOption.week)
                    }
                    .onChange(of: rangeSelection, perform: { newValue in
                        self.store.recompute(range: self.rangeSelection, gropuBy: self.groupBySelection)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowInsets(EdgeInsets())
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowSeparator(.hidden)
                    
                    Picker("Group By", selection: $groupBySelection) {
                        Text("Year").tag(TimePeriod.year)
                        Text("Month").tag(TimePeriod.month)
                        Text("Week").tag(TimePeriod.week)
                        Text("Day").tag(TimePeriod.day)
                    }
                    .onChange(of: groupBySelection, perform: { newValue in
                        self.store.recompute(range: self.rangeSelection, gropuBy: self.groupBySelection)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowInsets(EdgeInsets())
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowSeparator(.hidden)
                }  header: {
                    Text("Historical Data")
                }
            }
            .navigationTitle(self.store.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        self.show = false
                    }
                }
            }
        }
    }
}
