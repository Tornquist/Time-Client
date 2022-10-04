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
    
    var barWidth: MarkDimension {
        switch rangeSelection {
        case .week, .month:
            return .automatic
        case .threeMonths, .sixMonths:
            switch groupBySelection {
            case .year:
                return .fixed(9.0)
            case .month:
                return .fixed(8.0)
            case .week:
                return .fixed(7.0)
            case .day:
                return .automatic
            }
        case .year:
            switch groupBySelection {
            case .year, .month:
                return .fixed(9.0)
            case .week:
                return .fixed(3.0)
            case .day:
                return .automatic
            }
        case .all: // These values are based on ~5 years of data. Should be dynamic
            switch groupBySelection {
            case .year:
                return .fixed(9.0)
            case .month:
                return .fixed(2.0)
            case .week:
                return .fixed(0.7)
            case .day:
                return .automatic
            }
        }
    }
    
    @State var showWorkRuler: Bool = false
    var workRulerPlacement: TimeInterval {
        switch groupBySelection {
        case .day:
            return 28800 // 8 hours
        case .week:
            return 144000 // 40 hours
        default:
            return 0
        }
    }
    var enableWorkRuler: Bool {
        return self.groupBySelection == .day || self.groupBySelection == .week
    }
    var workRulerTitle: String {
        return self.groupBySelection == .day ? "8h" : "40h"
    }
    
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
                                        y: .value("Duration", entry.duration),
                                        width: barWidth
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
                            
                            if self.showWorkRuler && self.enableWorkRuler {
                                RuleMark(
                                    /* TODO: Averages: by included day for work? */
                                    y: .value("Average", self.workRulerPlacement)
                                )
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                                .annotation(position: .trailing, alignment: .leading) {
                                    Text(self.workRulerTitle)
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .chartXScale(domain: self.store.startRange...self.store.endRange)
                        .chartXAxis {
                            if rangeSelection == .all {
                                AxisMarks(values: .stride(by: .year))
                            } else if rangeSelection == .year || rangeSelection == .threeMonths || rangeSelection == .sixMonths {
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
                                    formatter.allowedUnits = [.hour, .minute]
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
                        Text("Last 6 Months").tag(CategoryReportStore.RangeOption.sixMonths)
                        Text("Last 3 Months").tag(CategoryReportStore.RangeOption.threeMonths)
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
                    
                    HStack {
                        Toggle(isOn: $showWorkRuler, label: {
                            Text("Work Ruler")
                        })
                        .disabled(self.enableWorkRuler == false)
                    }
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
