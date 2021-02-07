//
//  Home.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/6/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import Combine

struct Home: View {
    @State var isMoving = false
    @State var showMore = false
    
    @EnvironmentObject var categoryWrapper: ReactiveCategory
    
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
    
    func build(categories: [ReactiveCategory]) -> AnyView {
        if categories.count == 0 {
            return AnyView(EmptyView())
        }
        
        return AnyView(ForEach(categories, id: \.id) { (category) in
            if category.parentID == nil {
                ListItem(text: "ACCOUNT \(category.accountID)", tapped: {
                    withAnimation {
                        category.expanded.toggle()
                    }
                }) {
                    if !self.isMoving {
                        accountMenu()
                    }
                }
            } else {
                // Shift depth to make 1st level peer of account title
                ListItem(
                    text: category.name,
                    level: category.depth - 1,
                    open: category.expanded || self.isMoving,
                    showIcon: category.children.count > 0,
                    tapped: {
                        withAnimation {
                            category.expanded.toggle()
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
                    build(categories: self.categoryWrapper.children)
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
                            self.isMoving.toggle()
                        }
                    }
                }
            })
        }
    }
}


class ReactiveCategory: ObservableObject, Identifiable {
    var id: Int
    @Published var parentID: Int?
    @Published var accountID: Int
    @Published var name: String
    @Published var expanded: Bool
    @Published var children: [ReactiveCategory]
    
    @Published var parent: ReactiveCategory? = nil
    
    var cancellables = [AnyCancellable]()

    var depth: Int {
        guard accountID != -1 else {
            return 0 // Shortcut for wrapping class
        }
        guard parent != nil && parent?.accountID != -1 else {
            return 0 // Start counting depth at zero and do not count wrapper
        }
        
        return (self.parent?.depth ?? 0) + 1
    }
    
    init(
        id: Int,
        parentID: Int?,
        accountID: Int,
        name: String,
        expanded: Bool,
        children: [ReactiveCategory]
    ) {
        self.id = id
        self.parentID = parentID
        self.accountID = accountID
        self.name = name
        self.expanded = expanded
        self.children = children

        self.children.forEach { (child) in
            child.parent = self
            let c = child.objectWillChange.sink { self.objectWillChange.send() }
            self.cancellables.append(c)
        }
    }
    
    static func wrap(children: [ReactiveCategory]) -> ReactiveCategory {
        return ReactiveCategory(
            id: -1,
            parentID: nil,
            accountID: -1,
            name: "wrapper",
            expanded: true,
            children: children
        )
    }
}

#if DEBUG
struct Home_Previews: PreviewProvider {
    static func getCategoryData() -> ReactiveCategory {
        return ReactiveCategory.wrap(children: [
            ReactiveCategory(
                id: 1,
                parentID: nil,
                accountID: 1,
                name: "root",
                expanded: false,
                children: [
                    ReactiveCategory(
                        id: 2,
                        parentID: 1,
                        accountID: 1,
                        name: "Life",
                        expanded: false,
                        children: [
                            ReactiveCategory(
                                id: 3,
                                parentID: 2,
                                accountID: 1,
                                name: "Class",
                                expanded: false,
                                children: [
                                    ReactiveCategory(
                                        id: 4,
                                        parentID: 3,
                                        accountID: 1,
                                        name: "Data Science",
                                        expanded: false,
                                        children: [
                                            
                                        ]
                                    ),
                                    ReactiveCategory(
                                        id: 5,
                                        parentID: 3,
                                        accountID: 1,
                                        name: "Machine Learning A-Z",
                                        expanded: false,
                                        children: [
                                            
                                        ]
                                    )
                                ]
                            ),
                            ReactiveCategory(
                                id: 6,
                                parentID: 2,
                                accountID: 1,
                                name: "HOA",
                                expanded: false,
                                children: [
                                    
                                ]
                            ),
                            ReactiveCategory(
                                id: 7,
                                parentID: 2,
                                accountID: 1,
                                name: "Personal",
                                expanded: false,
                                children: [
                                    ReactiveCategory(
                                        id: 8,
                                        parentID: 7,
                                        accountID: 1,
                                        name: "Website",
                                        expanded: false,
                                        children: [
                                            
                                        ]
                                    )
                                ]
                            )
                        ]
                    ),
                    ReactiveCategory(
                        id: 9,
                        parentID: 1,
                        accountID: 1,
                        name: "Side Projects",
                        expanded: false,
                        children: [
                            ReactiveCategory(
                                id: 10,
                                parentID: 9,
                                accountID: 1,
                                name: "Keyboard",
                                expanded: false,
                                children: [
                                    
                                ]
                            ),
                            ReactiveCategory(
                                id: 11,
                                parentID: 9,
                                accountID: 1,
                                name: "Time",
                                expanded: false,
                                children: [
                                    
                                ]
                            ),
                            ReactiveCategory(
                                id: 12,
                                parentID: 9,
                                accountID: 1,
                                name: "Uplink",
                                expanded: false,
                                children: [
                                    
                                ]
                            )
                        ]
                    ),
                    ReactiveCategory(
                        id: 13,
                        parentID: 1,
                        accountID: 1,
                        name: "Work",
                        expanded: false,
                        children: [
                            ReactiveCategory(
                                id: 14,
                                parentID: 13,
                                accountID: 1,
                                name: "Job A",
                                expanded: false,
                                children: [
                                    
                                ]
                            ),
                            ReactiveCategory(
                                id: 15,
                                parentID: 13,
                                accountID: 1,
                                name: "Job B",
                                expanded: false,
                                children: [
                                    
                                ]
                            ),
                            ReactiveCategory(
                                id: 16,
                                parentID: 13,
                                accountID: 1,
                                name: "Job C",
                                expanded: false,
                                children: [
                                    
                                ]
                            )
                        ]
                    )
                ]
            ),
            ReactiveCategory(
                id: 17,
                parentID: nil,
                accountID: 2,
                name: "root",
                expanded: false,
                children: [
                    ReactiveCategory(
                        id: 18,
                        parentID: 17,
                        accountID: 2,
                        name: "A",
                        expanded: false,
                        children: [
                        ]
                    ),
                    ReactiveCategory(
                        id: 19,
                        parentID: 17,
                        accountID: 2,
                        name: "B",
                        expanded: false,
                        children: [
                        ]
                    )
                ]
            )
        ])
    }
    
    struct PreviewWrapper: View {
        @ObservedObject private var categoryData = Home_Previews.getCategoryData()
        
        var body: some View {
            Home()
                .environmentObject(categoryData)
                .environment(\.colorScheme, .dark)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
