//
//  CategoryTree.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class CategoryTree: Equatable {
    
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
    
    init(_ node: Category, _ children: [CategoryTree] = []) {
        self.node = node
        self.children = children
        self.children.forEach({ $0.parent = self })
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
    
    internal func getOffset(withChild targetChild: Category, overrideExpanded showAll: Bool = false) -> (Int, Bool) {
        guard self.node.id != targetChild.id else { return (0, true) }
        guard self.expanded || showAll else { return (0, false) }
        
        var runningOffset = 0
        var foundTarget = false
        var visibleTarget = true
        
        self.children.enumerated().forEach { (i, child) in
            guard !foundTarget else { return }

            let inChildTree = child.findItem(withID: targetChild.id) != nil
            let displayCostOfChild = 1
            
            if inChildTree {
                let (finalAdjustment, visible) = child.getOffset(withChild: targetChild, overrideExpanded: showAll)
                guard visible else {
                    visibleTarget = false
                    return
                }
                
                runningOffset = runningOffset + displayCostOfChild + finalAdjustment
                foundTarget = true
            } else {
                let displayedChildrenOfChild = child.numberOfDisplayRows(overrideExpanded: showAll)
                runningOffset = runningOffset + displayCostOfChild + displayedChildrenOfChild
            }
        }
        
        return (runningOffset, foundTarget && visibleTarget)
    }
    
    public func getOffset(withChild targetChild: Category, overrideExpanded showAll: Bool = false) -> Int? {       
        let (offset, foundTarget) = self.getOffset(withChild: targetChild, overrideExpanded: showAll)
        // If found, count self (+1) to offset from minimum of 0 if found as first child
        return foundTarget ? offset : nil
    }
    
    // MARK: - Store and Support Operations
    
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
    
    // MARK: - Equatable
    
    public static func ==(lhs: CategoryTree, rhs: CategoryTree) -> Bool {
        guard lhs.node.id == rhs.node.id else { return false }
        guard lhs.node.accountID == rhs.node.accountID else { return false }
        guard lhs.children.count == rhs.children.count else { return false }
        
        let sortedLhsChildren = lhs.children.sorted { $0.id < $1.id }
        let sortedRhsChildren = rhs.children.sorted { $0.id < $1.id }
        
        let childrenEqual = sortedLhsChildren.enumerated().map({ (i, _) -> Bool in
            let lhsChild = sortedLhsChildren[i]
            let rhsChild = sortedRhsChildren[i]
            return lhsChild == rhsChild
        }).reduce(true, { $0 && $1 })
        
        return childrenEqual
    }
}
