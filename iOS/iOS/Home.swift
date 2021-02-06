//
//  Home.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/6/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct Home: View {

    @State var isMoving = false
    @State var showMore = false
    
    func accountMenu() -> some View {
        Menu {
            Button(action: {  }, label: {
                Label("Rename", systemImage: "text.cursor")
            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
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
        }
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
                    ListItem(text: "ACCOUNT 1") {
                        accountMenu()
                    }
                    ListItem(text: "Side Projects", level: 0, open: true) {
                        categoryMenu()
                    }
                    ListItem(text: "Time", level: 1, open: true) {
                        categoryMenu()
                    }
                    ListItem(text: "Fixes", level: 2, open: false) {
                        categoryMenu()
                    }
                    ListItem(text: "Work", level: 0, open: false) {
                        categoryMenu()
                    }
                }
                .listRowInsets(EdgeInsets())

                if !isMoving {
                    Section {
                        ListItem(text: "More", level: 0, open: self.showMore)
                            .onTapGesture {
                                withAnimation {
                                    self.showMore = !self.showMore
                                }
                            }
                        if showMore {
                            ListItem(text: "Add Account", level: 0, open: true, showIcon: false)
                            ListItem(text: "Import Records", level: 0, open: false, showIcon: false)
                            ListItem(text: "Sign Out", level: 0, open: false, showIcon: false)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(isMoving ? "Select Destination" : "Time")
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
//            .environment(\.colorScheme, .dark)
    }
}
