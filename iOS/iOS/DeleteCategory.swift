//
//  DeleteCategory.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct DeleteCategory: View {
    @Binding var category: TimeSDK.Category?
    @Binding var show: Bool
    @EnvironmentObject var warehouse: Warehouse
    
    enum DeleteType: Identifiable {
        case standaloneCategory
        case entireTree
        case moveChildren
        
        var id: Int { hashValue }
    }
    
    @State var showDelete: DeleteType? = nil
    
    var name: String {
        return self.warehouse.getName(for: category)
    }
    var displayName: Text {
        return Text(name).bold()
    }
    
    var numDirectEntries: Int? {
        return countDirectEntries()
    }
    var displayDirectEntries: Text {
        return buildDisplayValue(numDirectEntries)
    }
    var directEntriesWord: String {
        return buildDisplayWord(numDirectEntries, "entry", "entries")
    }
    
    var numChildCategories: Int? {
        return countChildCategories()
    }
    var displayChildCategories: Text {
        return buildDisplayValue(numChildCategories)
    }
    var directChildCategoriesWord: String {
        return buildDisplayWord(numChildCategories, "category", "categories")
    }
    
    var numDownstreamEntries: Int? {
        countDownstreamEntries()
    }
    var displayDownstreamEntries: Text {
        return buildDisplayValue(numDownstreamEntries)
    }
    var downstreamEntriesWord: String {
        return buildDisplayWord(numDownstreamEntries, "entry", "entries")
    }
    
    var hasChildren: Bool {
        return numChildCategories != nil && numChildCategories! > 0
    }
    
    let redLowerDelete = Text("delete").foregroundColor(Color(.systemRed))
    let redDelete = Text("Delete").foregroundColor(Color(.systemRed))
    let greenReassign = Text("Reassign").foregroundColor(Color(.systemGreen))
    
    // MARK: - Counting
    
    func countDirectEntries() -> Int? {
        guard let category = category else {
            return nil
        }
        return self.warehouse.entries.filter({ $0.categoryID == category.id }).count
    }

    func countChildCategories() -> Int? {
        guard
            let category = category,
            let tree = self.warehouse.time?.store.categoryTrees[category.accountID],
            let leaf = tree.findItem(withID: category.id) else {
            return nil
        }

        return leaf.listCategories().count - 1 // Don't count self
    }
    
    func countDownstreamEntries() -> Int? {
        guard
            let category = category,
            let tree = self.warehouse.time?.store.categoryTrees[category.accountID],
            let leaf = tree.findItem(withID: category.id) else {
            return nil
        }

        let childCategoryIds = leaf.listCategories().compactMap { (testCategory) -> Int? in
            guard category.id != testCategory.id else {
                return nil
            }
            return testCategory.id
        }

        return self.warehouse.entries.filter({ childCategoryIds.contains($0.categoryID) }).count
    }
    
    // MARK: - Display Helpers
        
    func buildDisplayValue(_ value: Int?) -> Text {
        return value != nil ? Text("\(value!)").bold() : Text("")
    }
    
    func buildDisplayWord(_ value: Int?, _ singular: String, _ plural: String) -> String {
        return value == 1 ? singular : plural
    }
    
    func format(_ text: Text) -> some View {
        return HStack {
            text
            Spacer()
        }
    }
    
    // MARK: - Display
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 14) {
                        format(Text("Are you sure you wish to remove the category \(displayName)?"))
                        
                        VStack {
                            format(Text("\(displayName) has:"))
                            
                            if numDirectEntries != nil {
                                format(Text("• \(displayDirectEntries) directly attached \(directEntriesWord)."))
                            }
                            if numChildCategories != nil {
                                format(Text("• \(displayChildCategories) child \(directChildCategoriesWord)."))
                            }
                            if numDownstreamEntries != nil {
                                format(Text("• \(displayDownstreamEntries) downstream \(downstreamEntriesWord)."))
                            }
                        }
                    }.padding([.top, .bottom], 10)
                }
                
                if hasChildren {
                    Section(header: Text("Delete \(displayName) and children")) {
                        VStack(spacing: 14) {
                            VStack {
                                format(Text("This will:"))

                                if numDirectEntries != nil {
                                    format(Text("• \(redDelete) the \(displayDirectEntries) directly attached \(directEntriesWord)."))
                                }
                                if numChildCategories != nil {
                                    format(Text("• \(redDelete) the \(displayChildCategories) child \(directChildCategoriesWord)."))
                                }
                                if numDownstreamEntries != nil {
                                    format(Text("• \(redDelete) the \(displayDownstreamEntries) downstream \(downstreamEntriesWord)."))
                                }
                            }

                            Button("Delete \(displayName) and children", action: {
                                self.showDelete = .entireTree
                            })
                                .foregroundColor(Color(.systemRed))
                        }.padding([.top, .bottom], 10)
                    }
                    
                    Section(header: Text("Delete \(displayName) and move children")) {
                        VStack(spacing: 14) {
                            VStack {
                                format(Text("This will:"))

                                if numDirectEntries != nil {
                                    format(Text("• \(redDelete) the \(displayDirectEntries) directly attached \(directEntriesWord)."))
                                }
                                if numChildCategories != nil {
                                    format(Text("• \(greenReassign) the \(displayChildCategories) child \(directChildCategoriesWord) to \(displayName)'s parent."))
                                }
                                if numDownstreamEntries != nil {
                                    format(Text("• Do nothing to the \(displayDownstreamEntries) downstream \(downstreamEntriesWord)."))
                                }
                            }

                            Button("Delete \(displayName) and move children", action: {
                                self.showDelete = .moveChildren
                            })
                                .foregroundColor(Color(.systemRed))
                        }.padding([.top, .bottom], 10)
                    }
                } else {
                    Section(header: Text("Delete \(displayName)")) {
                        VStack(spacing: 14) {
                            VStack {
                                format(Text("This will \(redLowerDelete) the \(displayDirectEntries) directly attached \(directEntriesWord) and the \(displayName) category."))
                            }

                            Button("Delete \(displayName)", action: {
                                self.showDelete = .standaloneCategory
                            })
                                .foregroundColor(Color(.systemRed))
                        }.padding([.top, .bottom], 10)
                    }
                }
            }
            .navigationTitle("Delete Category")
            .listStyle(InsetGroupedListStyle())
            .alert(item: $showDelete, content: { (option) -> Alert in
                let message: String = {
                    switch option {
                    case .standaloneCategory:
                        return "Are you sure you with to delete \(self.name)?"
                    case .entireTree:
                        return "Are you sure you wish to delete \(self.name) and its children?"
                    case .moveChildren:
                        return "Are you sure you wish to delete \(self.name) and move its children?"
                    }
                }()
                return Alert(
                    title: Text("Confirm Deletion"),
                    message: Text(message),
                    primaryButton: .default(Text("Delete"), action: {
                        let deleteAll = option != .moveChildren
                        if let category = category {
                            self.warehouse.time?.store.deleteCategory(withID: category.id, andChildren: deleteAll, completion: nil)
                        }
                        
                        // Perform action
                        self.show = false
                    }),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.show = false
                    }
                }
            }
        }
    }
}

#if DEBUG
struct DeleteCategory_Previews: PreviewProvider {
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

        return DeleteCategory(category: categoryBinding, show: $show)
            .environmentObject(warehouse)
            .environment(\.colorScheme, .dark)
    }
}
#endif
