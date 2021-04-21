//
//  AddCategory.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct AddCategory: View {
    @Binding var category: TimeSDK.Category?
    @Binding var show: Bool
    
    var onSave: ((String) -> ())? = nil
    
    @EnvironmentObject var warehouse: Warehouse
    
    var body: some View {
        TextModal(
            title: "Add Category",
            description:
                Text("Enter a name for the new child of ") + Text(self.warehouse.getName(for: category)).fontWeight(.black),
            placeholder: "Child name",
            show: $show,
            onSave: { (newName) in
                if let category = category {
                    warehouse.time?.store.addCategory(withName: newName, to: category) { (success, newCategory) in
                        if success {
                            self.warehouse.showChildrenOf(category)
                        }
                    }
                }
                self.show = false
            }
        )
    }
}

#if DEBUG
struct AddCategory_Previews: PreviewProvider {
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

        return AddCategory(category: categoryBinding, show: $show)
            .environmentObject(warehouse)
            .environment(\.colorScheme, .dark)
    }
}
#endif
