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
    
    enum GraphStyle: String {
        case bar = "bar"
        case line = "line"
        case point = "point"
    }
    @State var graphStyle: GraphStyle = .bar
    
    let chartHeight: CGFloat = 300
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if store.loading {
                        HStack {
                            Spacer()
                            Text("Loading")
                                .italic()
                                .foregroundColor(Color(UIColor.placeholderText))
                            Spacer()
                        }.frame(height: chartHeight)
                    } else if store.graphData.count > 0 {
                        Chart {
                            // Changing point types inside the foreach prevented compilation
                            switch graphStyle {
                            case .bar:
                                ForEach(self.store.graphData) { entry in
                                    BarMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Duration", entry.duration)
                                    )
                                    .foregroundStyle(by: .value("Type", entry.category))
                                }
                            case .line:
                                ForEach(self.store.graphData) { entry in
                                    LineMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Duration", entry.duration)
                                    )
                                    .foregroundStyle(by: .value("Type", entry.category))
                                }
                            case .point:
                                ForEach(self.store.graphData) { entry in
                                    PointMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Duration", entry.duration)
                                    )
                                    .foregroundStyle(by: .value("Type", entry.category))
                                }
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
                        .frame(height: chartHeight)
                    } else {
                        HStack {
                            Spacer()
                            Text("No data")
                                .italic()
                                .foregroundColor(Color(UIColor.placeholderText))
                            Spacer()
                        }
                        .frame(height: chartHeight)
                    }
                } header:  {
                    Text("Recorded Data")
                }
                
                Section {
                    Picker("Timeframe", selection: $rangeSelection) {
                        Text("All time").tag(CategoryReportStore.RangeOption.all)
                        Text("Last Year").tag(CategoryReportStore.RangeOption.year)
                        Text("Last Month").tag(CategoryReportStore.RangeOption.month)
                        Text("Last Week").tag(CategoryReportStore.RangeOption.week)
                    }
                    .onChange(of: rangeSelection, perform: { newValue in
                        self.store.recompute(range: self.rangeSelection, gropuBy: self.groupBySelection)
                    })
                    .pickerStyle(.menu)
                    
                    Picker("Group By", selection: $groupBySelection) {
                        Text("Year").tag(TimePeriod.year)
                        Text("Month").tag(TimePeriod.month)
                        Text("Week").tag(TimePeriod.week)
                        Text("Day").tag(TimePeriod.day)
                    }
                    .onChange(of: groupBySelection, perform: { newValue in
                        self.store.recompute(range: self.rangeSelection, gropuBy: self.groupBySelection)
                    })
                    .pickerStyle(.menu)

                    Picker("Style", selection: $graphStyle) {
                        Text("Bar Graph").tag(GraphStyle.bar)
                        Text("Line Graph").tag(GraphStyle.line)
                        Text("Scatterplot").tag(GraphStyle.point)
                    }
                    .pickerStyle(.menu)
                } header:  {
                    Text("Controls")
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
