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
    @State var isMoving = false
    @State var showMore = false
    
    @EnvironmentObject var warehouse: Warehouse
    
    func accountMenu() -> some View {
        Menu {
            Button(action: {  }, label: {
                Label("Rename", systemImage: "text.cursor")
            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
                .frame(width: 16, height: 16, alignment: .center)
        }
    }
    
    func categoryMenu() -> some View {
        Menu {
            Menu {
                Button(action: {  }, label: {
                    Label("Add Child", systemImage: "plus")
                })
                Button(action: {  }, label: {
                    Label("Move", systemImage: "arrow.up.and.down")
                })
                Button(action: {  }, label: {
                    Label("Rename", systemImage: "text.cursor")
                })
                Button(action: {  }, label: {
                    Label("Delete", systemImage: "trash")
                })
            } label: {
                Label("Modify", systemImage: "gear")
            }
            Button(action: {  }, label: {
                Label("Start", systemImage: "play.circle")
            })
            Button(action: {  }, label: {
                Label("Record", systemImage: "smallcircle.fill.circle")
            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
                .frame(width: 16, height: 16, alignment: .center)
        }
    }
    
    func build(categories: [CategoryTree]) -> AnyView {
        if categories.count == 0 {
            return AnyView(EmptyView())
        }
        
        return AnyView(ForEach(categories, id: \.id) { (category) in
            if category.parent == nil {
                ListItem(text: "ACCOUNT \(category.node.accountID)", tapped: {
                    withAnimation {
                        category.toggleExpanded()
                    }
                }) {
                    if !self.isMoving {
                        accountMenu()
                    }
                }
            } else {
                // Shift depth to make 1st level peer of account title
                ListItem(
                    text: category.node.name,
                    level: category.depth - 1,
                    open: category.expanded || self.isMoving,
                    showIcon: category.children.count > 0,
                    tapped: {
                        withAnimation {
                            category.toggleExpanded()
                        }
                    }
                ) {
                    if !self.isMoving {
                        categoryMenu()
                    }
                }
                .transition(.slide)
            }
            
            if category.expanded || self.isMoving {
                build(categories: category.children)
            }
        })
    }
    
    var body: some View {
        NavigationView {
            List {
                if !isMoving {
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
                }
                    
                Section(header: isMoving ? nil : Text("Accounts").titleStyle()) {
                    build(categories: self.warehouse.trees)
                }
                .listRowInsets(EdgeInsets())

                if !isMoving {
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
                            ListItem(text: "Moving", level: 0, open: false, showIcon: false, tapped: {
                                self.isMoving.toggle()
                            })
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(isMoving ? "Select Destination" : "Time")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isMoving {
                        Button("Cancel") {
                            isMoving.toggle()
                        }
                    }
                }
            })
        }
    }
}

#if DEBUG
struct Home_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @ObservedObject private var warehouse = Warehouse.getPreviewWarehouse()
        
        var body: some View {
            Home()
                .environmentObject(warehouse)
                .environment(\.colorScheme, .dark)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
