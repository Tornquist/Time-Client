//
//  MoveCategory.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/7/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct MoveCategory: View {
    @Binding var categoryID: Int
    @Binding var show: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    CategoryList(isMoving: true, selectedCategoryID: $categoryID)
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
    @State static var categoryID: Int = 11
    @State static var show: Bool = true
    
    static var previews: some View {
        let warehouse = Warehouse.getPreviewWarehouse()
        
        return MoveCategory(categoryID: $categoryID, show: $show)
            .environmentObject(warehouse)
            .environment(\.colorScheme, .dark)
    }
}
#endif
