//
//  Home.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/6/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import Combine
import TimeSDK

struct Home: View {
    
    @State var showMoving = false
    @State var actingCategoryID: Int = 0
    
    @State var showMore = false
    
    @EnvironmentObject var warehouse: Warehouse
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Metrics").titleStyle()) {
                    QuantityMetric(
                        total: "00:00:00",
                        description: "Today",
                        items: []
                    )
                    QuantityMetric(
                        total: "27:71:04",
                        description: "This Week",
                        items: [
                            QuantityMetric.QuantityItem(
                                name: "Project 1",
                                total: "23:46:55",
                                active: false
                            ),
                            QuantityMetric.QuantityItem(
                                name: "Project 2",
                                total: "00:19:27",
                                active: false
                            ),
                            QuantityMetric.QuantityItem(
                                name: "Project 3",
                                total: "03:46:11",
                                active: false
                            )
                        ]
                    )
                }
                .listRowInsets(EdgeInsets())
                .padding(EdgeInsets())
                
                Section(header: Text("Recents").titleStyle()) {
                    RecentCategory(name: "Time", parents: "Side Projects", action: .pause, active: true)
                    RecentCategory(name: "Time", parents: "Side Projects", action: .play, active: false)
                    RecentCategory(name: "Time", parents: "Side Projects", action: .play, active: false)
                    RecentCategory(name: "Time", parents: "Side Projects", action: .record, active: false)
                }
                .listRowInsets(EdgeInsets())
                    
                Section {
                    NavigationLink("Show All Entries", destination: Text("test"))
                        .foregroundColor(.blue)
                        .font(Font.system(size: 14.0))
                        .padding(.leading, -4.0)
                        .padding(.trailing, -4.0)
                }
                    
                Section(header: Text("Accounts").titleStyle()) {
                    CategoryList(
                        isMoving: false,
                        selectedCategoryID: $actingCategoryID,
                        showMoving: $showMoving
                    )
                }
                .listRowInsets(EdgeInsets())

                Section {
                    ListItem(text: "More", level: 0, open: self.showMore, tapped: {
                        withAnimation {
                            self.showMore = !self.showMore
                        }
                    })
                    if showMore {
                        ListItem(text: "Add Account", level: 0, open: true, showIcon: false)
                        ListItem(text: "Import Records", level: 0, open: false, showIcon: false)
                        ListItem(text: "Sign Out", level: 0, open: false, showIcon: false)
                    }
                }
                .background(Color(.systemGroupedBackground))
                .listRowInsets(EdgeInsets())
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Time")
            .sheet(isPresented: $showMoving, content: {
                MoveCategory(categoryID: $actingCategoryID, show: $showMoving)
            })
        }
    }
}

#if DEBUG
struct Home_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        var warehouse = Warehouse.getPreviewWarehouse()
        
        var body: some View {
            Home()
                .environmentObject(warehouse)
//                .environment(\.colorScheme, .dark)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
