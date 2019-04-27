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
    public var parent: CategoryTree?
    
    private var _numChildren: Int? = nil
    public var numChildren: Int {
        if self._numChildren == nil {
            self.recalculateChildren()
        }
        return self._numChildren!
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
    
    public func sortChildren() {
        // Default (and only) sorting method is alphabetically (ignoring case)
        self.children.sort { (treeA, treeB) -> Bool in
            return treeA.node.name.lowercased() < treeB.node.name.lowercased()
        }
        self.children.forEach({ $0.sortChildren() })
    }
    
    public func recalculateChildren(recursively: Bool = false) {
        if recursively { self.children.forEach({ $0.recalculateChildren(recursively: recursively) }) }
        
        self._numChildren = children.map({ $0.numChildren }).reduce(0, { $0 + $1 }) + children.count
    }
    
    public static func generateFrom(_ categories: [Category]) -> [CategoryTree] {
        // Setup
        let rootNodes = categories.filter({ $0.parentID == nil })
        var childNodes = categories.filter({ $0.parentID != nil })
        
        // Plan Trees
        let treeRoots = rootNodes.map({ CategoryTree($0) })
        
        // Grow Trees
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
        
        // Groom Trees
        treeRoots.forEach({ $0.sortChildren() })
        
        return treeRoots
    }
}
