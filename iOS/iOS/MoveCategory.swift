//
//  MoveCategory.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/7/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct MoveCategory: View {
    @Binding var movingCategory: TimeSDK.Category?
    @Binding var show: Bool
    
    @EnvironmentObject var warehouse: Warehouse
    
    func textColor(for category: TimeSDK.Category, canMove: Bool) -> Color {
        if category.id == movingCategory?.id {
            return Color(.systemRed)
        }
        
        guard canMove else {
            return Color(.secondaryLabel)
        }
        
        return Color(.label)
    }
    
    func backgroundColor(for category: TimeSDK.Category, canMove: Bool) -> Color {
        if category.id == movingCategory?.id {
            return Color.clear
        }
        
        guard canMove else {
            return Color(.systemGroupedBackground)
        }
        
        return Color.clear
    }
    
    func canMove(_ target: TimeSDK.Category?, to category: TimeSDK.Category) -> Bool {
        guard let safeTarget = target else {
            return false
        
        }
        return self.warehouse.time?.store.canMove(safeTarget, to: category) ?? false
    }
    
    func build(categories: [CategoryTree]) -> AnyView {
        if categories.count == 0 {
            return AnyView(EmptyView())
        }
        
        return AnyView(ForEach(categories, id: \.id) { (category) in
            let isAccount = category.parent == nil
            let text = isAccount
                ? "ACCOUNT \(category.node.accountID)"
                : category.node.name
            let viableChoice = canMove(movingCategory, to: category.node)
            
            ListItem(
                text: text,
                level: isAccount ? -1 : (category.depth - 1),
                open: true,
                showIcon: category.children.count > 0,
                tapped: {
                    // Selected destination
                }
            ).transition(.slide)
            .foregroundColor(textColor(for: category.node, canMove: viableChoice))
            .background(backgroundColor(for: category.node, canMove: viableChoice))
            
            build(categories: category.children)
        })
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    build(categories: self.warehouse.trees)
                }
                .listRowInsets(EdgeInsets())
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Destination")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        show = false
                    }
                }
            }
        }
    }
}

#if DEBUG
struct MoveCategory_Previews: PreviewProvider {
    @State static var show: Bool = true
    
    static var previews: some View {
        let warehouse = Warehouse.getPreviewWarehouse()
        let stringData = """
        {"id": 11, "parent_id": 9, "account_id": 1, "name": "Time"}
        """
        let data = stringData.data(using: .utf8)!
        let decoder = JSONDecoder()
        let category = try! decoder.decode(TimeSDK.Category.self, from: data)
        let categoryBinding = Binding<TimeSDK.Category?> { () -> TimeSDK.Category? in
            return category
        } set: { (_) in }

        
        return MoveCategory(movingCategory: categoryBinding, show: $show)
            .environmentObject(warehouse)
            .environment(\.colorScheme, .dark)
    }
}
#endif
