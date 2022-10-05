//
//  RecentSection.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct RecentSection: View {
    @EnvironmentObject var warehouse: Warehouse
    
    @State var handlingId: [Int: Bool] = [:]
    
    var categoryAction: ((TimeSDK.Category, CategoryMenu.Selection) -> Void)? = nil
    
    var body: some View {
        ForEach(self.warehouse.recentCategories) { (categoryTree) in
            let index = self.warehouse.recentCategories.firstIndex(of: categoryTree)
            
            let name = categoryTree.node.name
            let parentName = self.warehouse.getParentHierarchyName(categoryTree)
            let isActive = self.warehouse.openCategoryIDs.contains(categoryTree.id)
            let isRange = index != nil ? self.warehouse.recentCategoryIsRange[index!] : true
            let action = isActive
                ? TitleSubtitleActionView.Action.pause
                : (
                    isRange
                        ? TitleSubtitleActionView.Action.play
                        : TitleSubtitleActionView.Action.record
                )
            
            TitleSubtitleActionView(
                title: name,
                subtitle: parentName,
                action: action,
                active: isActive,
                loading: handlingId[categoryTree.id] ?? false,
                onTapText: {
                    categoryAction?(categoryTree.node, .analytics)
                },
                onTapButton: {
                    // This is in-line instead of using categoryAction so that
                    // the loading states can be tightly coupled.
                    Mainify {
                        handlingId[categoryTree.id] = true
                    }
                    if action == TitleSubtitleActionView.Action.record {
                        self.warehouse.time?.store.recordEvent(for: categoryTree.node, completion: { _ in
                            Mainify { handlingId[categoryTree.id] = false }
                        })
                    } else {
                        self.warehouse.time?.store.toggleRange(for: categoryTree.node, completion: { _ in
                            Mainify { handlingId[categoryTree.id] = false }
                        })
                    }
                }
            ).padding(.all, 16)
        }
    }
}
