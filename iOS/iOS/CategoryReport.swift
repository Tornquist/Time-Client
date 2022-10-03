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
    
    var body: some View {
        NavigationView {
            VStack {
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
                        AxisMarks(values: .stride(by: .weekOfYear))
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
                } else {
                    Text("No data")
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
