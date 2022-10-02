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
    
    @State var showModal: HomeModal? = nil
    @State var showAlert: HomeAlert? = nil
    @State var selectedCategory: TimeSDK.Category? = nil
    var signOut: (() -> ())? = nil
    
    @EnvironmentObject var warehouse: Warehouse
    
    let showSeconds = true
    
    enum HomeAlert: Identifiable {
        case addAccount
        
        var id: Int { hashValue }
    }
    
    enum HomeModal: Identifiable {
        case addChild
        case move
        case rename
        case delete
        case importList
        case report
        
        static func from(_ selection: AccountMenu.Selection) -> HomeModal? {
            switch selection {
            case .addChild:
                return HomeModal.addChild
            default:
                return nil
            }
        }
        
        static func from(_ selection: CategoryMenu.Selection) -> HomeModal? {
            switch selection {
            case .addChild:
                return HomeModal.addChild
            case .move:
                return HomeModal.move
            case .rename:
                return HomeModal.rename
            case .delete:
                return HomeModal.delete
            default:
                return nil
            }
        }
        
        var id: Int { hashValue }
    }
        
    func buildBinding(for modal: HomeModal) -> Binding<Bool> {
        let binding = Binding<Bool>(
            get: { return showModal == modal },
            set: { (newVal) in
                if newVal {
                    showModal = modal
                } else {
                    showModal = nil
                }
            }
        )
        return binding
    }
        
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Metrics").titleStyle()) {
                    MetricSection(
                        store: AnalyticsStore(for: self.warehouse),
                        showSeconds: showSeconds
                    )
                }
                .listRowInsets(EdgeInsets())
                .padding(EdgeInsets())
                .contentShape(Rectangle())
                .onTapGesture {
                    self.showModal = .report
                }
                
                if self.warehouse.recentCategories.count > 0 {
                    Section(header: Text("Recents").titleStyle()) {
                        RecentSection()
                    }
                    .listRowInsets(EdgeInsets())
                }
                    
                Section {
                    NavigationLink(
                        "Show All Entries",
                        destination: Entries()
                    )
                        .foregroundColor(.blue)
                        .font(Font.system(size: 14.0))
                        .padding(.leading, -4.0)
                        .padding(.trailing, -4.0)
                }

                ForEach(self.warehouse.accountTrees) { (tree) in
                    let isFirst = self.warehouse.accountTrees[0].id == tree.id
                    if isFirst {
                        Section(header: Text("Accounts").titleStyle()) {
                            CategoryList(
                                root: tree,
                                accountAction: handleAccountAction,
                                categoryAction: handleCategoryAction
                            )
                        }
                        .listRowInsets(EdgeInsets())
                    } else {
                        Section {
                            CategoryList(
                                root: tree,
                                accountAction: handleAccountAction,
                                categoryAction: handleCategoryAction
                            )
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                Section {
                    ListItem(text: "More", level: 0, open: self.showMore, tapped: {
                        withAnimation {
                            self.showMore = !self.showMore
                        }
                    })
                    if showMore {
                        ListItem(text: "Add Account", level: 0, open: true, showIcon: false) {
                            self.showAlert = .addAccount
                        }
                        ListItem(text: "Import Records", level: 0, open: false, showIcon: false) {
                            self.showModal = .importList
                        }
                        ListItem(text: "Sign Out", level: 0, open: false, showIcon: false) {
                            signOut?()
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .listRowInsets(EdgeInsets())
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Time")
            .alert(item: $showAlert, content: buildAlert)
            .sheet(item: $showModal, content: buildModal)
        }
    }
    
    func handleAccountAction(category: TimeSDK.Category, accountAction: AccountMenu.Selection) {
        switch accountAction {
        case .addChild:
            self.showModal = HomeModal.from(accountAction)
            self.selectedCategory = category
        case .rename:
            break // No actions yet
        }
    }
    
    func handleCategoryAction(category: TimeSDK.Category, categoryAction: CategoryMenu.Selection) {
        switch categoryAction {
        case .addChild, .move, .rename, .delete:
            self.showModal = HomeModal.from(categoryAction)
            self.selectedCategory = category
        case .toggleState:
            self.warehouse.time?.store.toggleRange(for: category, completion: nil)
        case .recordEvent:
            self.warehouse.time?.store.recordEvent(for: category, completion: nil)
        }
    }
    
    func buildAlert(_ option: HomeAlert) -> Alert {
        switch (option) {
        case .addAccount:
            return Alert(
                title: Text("Create Account"),
                message: Text("Are you sure you would like to create a new account?"),
                primaryButton: .default(Text("Create"), action: {
                    self.warehouse.time?.store.createAccount(completion: { (newAccount, error) in
                        self.warehouse.loadData(refresh: true)
                    })
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    func buildModal(_ option: HomeModal) -> AnyView {
        switch (option) {
        case .addChild:
            return AnyView(
                AddCategory(category: $selectedCategory, show: buildBinding(for: .addChild))
                    .environmentObject(self.warehouse)
            )
        case .move:
            return AnyView(
                MoveCategory(movingCategory: $selectedCategory, show: buildBinding(for: .move))
                    .environmentObject(self.warehouse)
            )
        case .rename:
            return AnyView(
                RenameCategory(category: $selectedCategory, show: buildBinding(for: .rename))
                    .environmentObject(self.warehouse)
            )
        case .delete:
            return AnyView(
                DeleteCategory(category: $selectedCategory, show: buildBinding(for: .delete))
                    .environmentObject(self.warehouse)
            )
        case .importList:
            return AnyView(
                ImportList(model: ImportModel(for: self.warehouse), show: buildBinding(for: .importList))
                    .environmentObject(self.warehouse)
            )
        case .report:
            return AnyView(
                QuantityMetricReport(
                    store: OtherAnalyticsStore(for: self.warehouse),
                    show: buildBinding(for: .importList),
                    showSeconds: showSeconds
                )
                .environmentObject(self.warehouse)
            )
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
