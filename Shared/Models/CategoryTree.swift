//
//  CategoryTree.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class CategoryTree {
    public var node: Category
    public var children: [CategoryTree]
    var parent: CategoryTree?
    
    public var numChildren: Int {
        return children.map({ $0.numChildren }).reduce(0, { $0 + $1 }) + children.count
    }
    
    public var depth: Int {
        return self.parent == nil ? 0 : self.parent!.depth + 1
    }
    
    init(_ node: Category) {
        self.node = node
        self.children = []
        self.parent = nil
    }
    
    public func findItem(withID id: Int) -> CategoryTree? {
        if node.id == id { return self }
        let found = children.map({ $0.findItem(withID: id) }).reduce(nil, { $0 ?? $1 })
        return found
    }
    
    func insert(item: Category) {
        let newTree = CategoryTree(item)
        newTree.parent = self
        self.children.append(newTree)
    }
    
    func asList() -> [Category] {
        var list = [self.node]
        self.children.forEach({ list.append(contentsOf: $0.asList()) })
        return list
    }
    
    public func getChild(withOffset offset: Int) -> Category? {
        let list = self.asList()
        return list.count - 1 > offset ? list[offset + 1] : nil
    }
    
    public static func generateFrom(_ categories: [Category]) -> [CategoryTree] {
        let rootNodes = categories.filter({ $0.parentID == nil })
        var childNodes = categories.filter({ $0.parentID != nil })
        
        let treeRoots = rootNodes.map({ CategoryTree($0) })
        var placedOne = false
        repeat {
            placedOne = false
            
            childNodes = childNodes.filter({ (node) -> Bool in
                let parent = treeRoots.map({ $0.findItem(withID: node.parentID! )}).reduce(nil, { $0 ?? $1 })
                if parent != nil {
                    parent!.insert(item: node)
                    placedOne = true
                    return false
                }
                return true
            })
        } while placedOne
        
        return treeRoots
    }
}
