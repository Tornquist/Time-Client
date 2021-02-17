//
//  CategoryList.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/7/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct CategoryList: View {
    
    var root: CategoryTree
    @EnvironmentObject var warehouse: Warehouse
    
    var accountAction: ((TimeSDK.Category, AccountMenu.Selection) -> Void)? = nil
    var categoryAction: ((TimeSDK.Category, CategoryMenu.Selection) -> Void)? = nil
    
    func build(categories: [CategoryTree]) -> AnyView {
        if categories.count == 0 {
            return AnyView(EmptyView())
        }
        
        return AnyView(ForEach(categories, id: \.id) { (category) in
            let isAccount = category.parent == nil
            let text = isAccount
                ? "ACCOUNT \(category.node.accountID)"
                : category.node.name
            
            ListItem(
                text: text,
                level: isAccount ? -1 : (category.depth - 1),
                open: category.expanded,
                showIcon: category.children.count > 0,
                tapped: {
                    withAnimation {
                        category.toggleExpanded()
                    }
                },
                trailingView: {
                    if isAccount {
                        AccountMenu(root: category.node, selected: accountAction)
                    } else {
                        let running = self.warehouse.openCategoryIDs.contains(category.id)
                        CategoryMenu(category: category.node, isRunning: running, selected: categoryAction)
                    }
                }
            )
            .foregroundColor(
                self.warehouse.openCategoryIDs.contains(category.id)
                    ? Color(.systemGreen)
                    : Color(.label)
            )
            
            if category.expanded {
                build(categories: category.children)
            }
        })
    }
    
    var body: some View {
        build(categories: [root])
    }
}

#if DEBUG
struct CategoryList_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        var warehouse = Warehouse.getPreviewWarehouse()
        var body: some View {
            NavigationView {
                List {
                    CategoryList(root: warehouse.trees[0])
                }
            }
                .environmentObject(warehouse)
                .environment(\.colorScheme, .dark)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
