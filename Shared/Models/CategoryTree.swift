//
//  CategoryTree.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class CategoryTree {
    
    // MARK: - Tree Properties
    
    public var id: Int { return self.node.id }
    public var node: Category
    public var children: [CategoryTree]
    public var parent: CategoryTree?
    
    public var depth: Int {
        return self.parent == nil ? 0 : self.parent!.depth + 1
    }
    
    private var _expanded: Bool = false
    public var expanded: Bool { return self._expanded }
    
    // MARK: - Init
    
    init(_ node: Category) {
        self.node = node
        self.children = []
        self.parent = nil
    }
    
    // MARK: - Tree Modification and Query
    
    public func toggleExpanded(forceTo goal: Bool? = nil) {
        guard self.children.count > 0 else {
            self._expanded = false
            return
        }
        
        if goal == nil {
            self._expanded = !self.expanded
        } else {
            self._expanded = goal!
        }
    }
    
    public func numberOfDisplayRows(overrideExpanded showAll: Bool = false, includeRoot: Bool = false) -> Int {
        // Unless root rows counted through parent.children
        let selfRows = includeRoot && self.parent == nil ? 1 : 0
        let childRows = showAll || self.expanded
            ? self.children.count + self.children.map({ $0.numberOfDisplayRows(overrideExpanded: showAll, includeRoot: includeRoot) }).reduce(0, { $0 + $1 })
            : 0
        return selfRows + childRows
    }
    
    internal func getChild(withOffset offset: Int, overrideExpanded showAll: Bool = false) -> (CategoryTree?, Int?) {
        // Found item, exit.
        guard offset != 0 else { return (self, nil) }
        
        // If not searching tree, stop and return a cost of 0 (no children evaluated)
        guard self.expanded || showAll else { return (nil, 0) }

        var foundTarget: CategoryTree? = nil
        var itemsSearched = 0

        self.children.enumerated().forEach { (i, child) in
            guard foundTarget == nil else { return }
            
            itemsSearched = itemsSearched + 1
            let (found, additionalItemsSearched) = child.getChild(withOffset: offset - itemsSearched, overrideExpanded: showAll)

            if found != nil {
                foundTarget = found
            } else if (additionalItemsSearched != nil) {
                itemsSearched = itemsSearched + additionalItemsSearched!
            }
        }
        
        return (foundTarget, itemsSearched)
    }
    
    public func getChild(withOffset offset: Int, overrideExpanded showAll: Bool = false) -> CategoryTree? {
        let (found, _) = self.getChild(withOffset: offset, overrideExpanded: showAll)
        return found
    }
    
    // MARK: - Store and Support Operations
    
    func findItem(withID id: Int) -> CategoryTree? {
        if node.id == id { return self }
        let found = children.map({ $0.findItem(withID: id) }).reduce(nil, { $0 ?? $1 })
        return found
    }
    
    func insert(item: Category) {
        let newTree = CategoryTree(item)
        newTree.parent = self
        self.children.append(newTree)
    }
    
    func listCategories() -> [Category] {
        var list = [self.node]
        self.children.forEach({ list.append(contentsOf: $0.listCategories()) })
        return list
    }
    
    func sortChildren() {
        // Default (and only) sorting method is alphabetically (ignoring case)
        self.children.sort { (treeA, treeB) -> Bool in
            return treeA.node.name.lowercased() < treeB.node.name.lowercased()
        }
        self.children.forEach({ $0.sortChildren() })
    }
    
    // MARK: - Tree Construction
    
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
