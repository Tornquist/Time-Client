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
    @State var showMore = false
    
    let showSeconds = true
    var emptyDuration: String {
        return showSeconds ? "00:00:00" : "00:00"
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum HomeAction: Identifiable {
        case addChild
        case move
        case rename
        case delete
        
        var id: Int { hashValue }
    }
    
    @State var selectedAction: HomeAction? = nil
    @State var selectedCategory: TimeSDK.Category? = nil
    
    @EnvironmentObject var warehouse: Warehouse
    
    func buildBinding(for action: HomeAction) -> Binding<Bool> {
        let binding = Binding<Bool>(
            get: { return selectedAction == action },
            set: { (newVal) in
                if newVal {
                    selectedAction = action
                } else {
                    selectedAction = nil
                }
            }
        )
        return binding
    }
        
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Metrics").titleStyle()) {
                    QuantityMetric(
                        total: self.warehouse.dayTotal?.displayDuration(withSeconds: showSeconds) ?? emptyDuration,
                        description: "Today",
                        items: self.warehouse.dayCategories.map({ (result) -> QuantityMetric.QuantityItem in
                            QuantityMetric.QuantityItem(
                                name: self.warehouse.getName(for: result.categoryID),
                                total: result.displayDuration(withSeconds: showSeconds),
                                active: result.open
                            )
                        })
                    )
                    QuantityMetric(
                        total: self.warehouse.weekTotal?.displayDuration(withSeconds: showSeconds) ?? emptyDuration,
                        description: "This Week",
                        items: self.warehouse.weekCategories.map({ (result) -> QuantityMetric.QuantityItem in
                            QuantityMetric.QuantityItem(
                                name: self.warehouse.getName(for: result.categoryID),
                                total: result.displayDuration(withSeconds: showSeconds),
                                active: result.open
                            )
                        })
                    )
                }
                .listRowInsets(EdgeInsets())
                .padding(EdgeInsets())
                
                Section(header: Text("Recents").titleStyle()) {
                    ForEach(self.warehouse.recentCategories.indices) { (index) -> RecentCategory in
                        let categoryTree = self.warehouse.recentCategories[index]
                        let name = categoryTree.node.name
                        let parentName = self.warehouse.getParentHierarchyName(categoryTree)
                        let isActive = self.warehouse.openCategoryIDs.contains(categoryTree.id)
                        let isRange = self.warehouse.recentCategoryIsRange[index]
                        let action = isActive
                            ? RecentCategory.Action.pause
                            : (
                                isRange
                                    ? RecentCategory.Action.play
                                    : RecentCategory.Action.record
                            )
                        
                        RecentCategory(name: name, parents: parentName, action: action, active: isActive) {
                            if action == RecentCategory.Action.record {
                                self.warehouse.time?.store.recordEvent(for: categoryTree.node, completion: nil)
                            } else {
                                self.warehouse.time?.store.toggleRange(for: categoryTree.node, completion: nil)
                            }
                        }
                    }
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
                    CategoryList(selectedAction: $selectedAction, selectedCategory: $selectedCategory)
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
            .sheet(item: $selectedAction) { (option) -> AnyView in
                switch (option) {
                case .addChild:
                    return AnyView(Text("Add Child").environmentObject(self.warehouse))
                case .move:
                    return AnyView(MoveCategory(
                        movingCategory: $selectedCategory,
                        show: buildBinding(for: .move)
                    ).environmentObject(self.warehouse))
                case .rename:
                    return AnyView(Text("Rename").environmentObject(self.warehouse))
                case .delete:
                    return AnyView(Text("Delete").environmentObject(self.warehouse))
                }
            }
        }.onReceive(timer, perform: { _ in
            self.warehouse.refreshAsNeeded()
        })
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
