//
//  Warehouse.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/7/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation
import Combine
import TimeSDK

class Warehouse: ObservableObject {
    
    private static var _shared: Warehouse? = nil
    static var shared: Warehouse {
        get {
            if _shared == nil {
                _shared = Warehouse(for: Time.shared)
            }
            
            return _shared!
        }
    }
    
    var time: Time? = nil
    @Published var trees: [CategoryTree] = []
    
    var cancellables = [AnyCancellable]()
        
    init(trees: [CategoryTree]) {
        self.trees = trees
        self.trees.forEach { (tree) in
            let c = tree.objectWillChange.sink { self.objectWillChange.send() }
            self.cancellables.append(c)
        }
    }
    
    convenience init(for time: Time) {
        let trees = Time.shared.store.categoryTrees.values.sorted { (a, b) -> Bool in
            return a.node.accountID < b.node.accountID
        }
        
        self.init(trees: trees)
        
        self.time = time
    }
   
    #if DEBUG
    static func getPreviewWarehouse() -> Warehouse {
        let data = """
    [
        {"id": 1, "parent_id": null, "account_id": 1, "name": "root"},
        {"id": 2, "parent_id": 1, "account_id": 1, "name": "Life"},
        {"id": 3, "parent_id": 2, "account_id": 1, "name": "Class"},
        {"id": 4, "parent_id": 3, "account_id": 1, "name": "Data Science"},
        {"id": 5, "parent_id": 3, "account_id": 1, "name": "Machine Learning A-Z"},
        {"id": 6, "parent_id": 2, "account_id": 1, "name": "HOA"},
        {"id": 7, "parent_id": 2, "account_id": 1, "name": "Personal"},
        {"id": 8, "parent_id": 7, "account_id": 1, "name": "Website"},
        {"id": 9, "parent_id": 1, "account_id": 1, "name": "Side Projects"},
        {"id": 10, "parent_id": 9, "account_id": 1, "name": "Keyboard"},
        {"id": 11, "parent_id": 9, "account_id": 1, "name": "Time"},
        {"id": 12, "parent_id": 9, "account_id": 1, "name": "Uplink"},
        {"id": 13, "parent_id": 1, "account_id": 1, "name": "Work"},
        {"id": 14, "parent_id": 13, "account_id": 1, "name": "Job A"},
        {"id": 15, "parent_id": 13, "account_id": 1, "name": "Job B"},
        {"id": 16, "parent_id": 13, "account_id": 1, "name": "Job C"},
        {"id": 17, "parent_id": null, "account_id": 2, "name": "root"},
        {"id": 18, "parent_id": 17, "account_id": 2, "name": "A"},
        {"id": 19, "parent_id": 17, "account_id": 2, "name": "B"}
    ]
    """
        
        let decoder = JSONDecoder()
        let categories = try! decoder.decode([TimeSDK.Category].self, from: data.data(using: .utf8)!)
        let trees = CategoryTree.generateFrom(categories)
        let store = Warehouse(trees: trees)
        return store
    }
    #endif
}
