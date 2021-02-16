//
//  RecentSection.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct RecentSection: View {
    @EnvironmentObject var warehouse: Warehouse
    
    var body: some View {
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
}
