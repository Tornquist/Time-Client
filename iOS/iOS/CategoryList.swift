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
    var isMoving: Bool
    
    @Binding var selectedCategoryID: Int
    var showMoving: Binding<Bool>? = nil
    
    @EnvironmentObject var warehouse: Warehouse
    
    func accountMenu(for accountID: Int) -> some View {
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
    
    func categoryMenu(for category: TimeSDK.Category) -> some View {
        Menu {
            Menu {
                Button(action: {  }, label: {
                    Label("Add Child", systemImage: "plus")
                })
                Button(action: {
                    showMoving?.wrappedValue = true
                }, label: {
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
            let isAccount = category.parent == nil
            let text = isAccount
                ? "ACCOUNT \(category.node.accountID)"
                : category.node.name

            ListItem(
                text: text,
                level: isAccount ? -1 : (category.depth - 1),
                open: category.expanded || self.isMoving,
                showIcon: category.children.count > 0,
                tapped: {
                    withAnimation {
                        category.toggleExpanded()
                    }
                }) {
                if !self.isMoving {
                    if isAccount {
                        accountMenu(for: category.node.accountID)
                    } else {
                        categoryMenu(for: category.node)
                    }
                }
            }.transition(.slide)
            
            if category.expanded || self.isMoving {
                build(categories: category.children)
            }
        })
    }
    
    var body: some View {
        build(categories: self.warehouse.trees)
    }
}

#if DEBUG
struct CategoryList_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        @State var categoryID = 1
        
        var warehouse = Warehouse.getPreviewWarehouse()
        
        var body: some View {
            NavigationView {
                List {
                    CategoryList(isMoving: true, selectedCategoryID: $categoryID)
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
