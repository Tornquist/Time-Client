//
//  Test_CategoryTree.swift
//  Shared
//
//  Created by Nathan Tornquist on 5/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_CategoryTree: XCTestCase {
    func test_equatable() {
        let nodeRootA = TimeSDK.Category(id: 1, parentID: nil, accountID: 1, name: "root")
        let nodeRootB = TimeSDK.Category(id: 10, parentID: nil, accountID: 2, name: "root")
        let nodeRootA_mod = TimeSDK.Category(id: 1, parentID: nil, accountID: 2, name: "root")
        let nodeA = TimeSDK.Category(id: 2, parentID: 1, accountID: 1, name: "A")
        let nodeB = TimeSDK.Category(id: 3, parentID: 1, accountID: 1, name: "B")
        let nodeC = TimeSDK.Category(id: 4, parentID: 1, accountID: 1, name: "C")
        let nodeD = TimeSDK.Category(id: 5, parentID: 4, accountID: 1, name: "1")
        
        var treeA: CategoryTree! = nil
        var treeB: CategoryTree! = nil
        
        // Test Same Root
        treeA = CategoryTree(nodeRootA, [])
        treeB = CategoryTree(nodeRootA, [])
        XCTAssertEqual(treeA, treeB)
        
        // Test Different Root
        treeA = CategoryTree(nodeRootA, [])
        treeB = CategoryTree(nodeRootB, [])
        XCTAssertNotEqual(treeA, treeB)
        
        // Test Different Accounts
        treeA = CategoryTree(nodeRootA, [])
        treeB = CategoryTree(nodeRootA_mod, [])
        XCTAssertNotEqual(treeA, treeB)
        
        // Test Same Children
        treeA = CategoryTree(nodeRootA, [
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, []),
            CategoryTree(nodeC, [])
        ])
        treeB = CategoryTree(nodeRootA, [
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, []),
            CategoryTree(nodeC, [])
        ])
        XCTAssertEqual(treeA, treeB)
        
        // Test Mismatched Children
        treeA = CategoryTree(nodeRootA, [
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, []),
            CategoryTree(nodeC, [])
        ])
        treeB = CategoryTree(nodeRootA, [
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, []),
            CategoryTree(nodeC, [CategoryTree(nodeD, [])])
        ])
        XCTAssertNotEqual(treeA, treeB)
        
        // Test Children Sorting is Irrelevant
        treeA = CategoryTree(nodeRootA, [
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, []),
            CategoryTree(nodeC, [])
        ])
        treeB = CategoryTree(nodeRootA, [
            CategoryTree(nodeC, []),
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, [])
        ])
        XCTAssertEqual(treeA, treeB)
    }
    
    func test_generatingTrees() {
        self.continueAfterFailure = false
        
        var categories: [TimeSDK.Category] = [
            Category(id: 1, parentID: nil, accountID: 1, name: "root"),
            Category(id: 2, parentID: 1, accountID: 1, name: "A"),
            Category(id: 3, parentID: 1, accountID: 1, name: "B"),
            Category(id: 4, parentID: 1, accountID: 1, name: "C"),
            Category(id: 5, parentID: 4, accountID: 1, name: "1"),
            Category(id: 6, parentID: 5, accountID: 1, name: "First"),
            Category(id: 7, parentID: 5, accountID: 1, name: "Second"),
            Category(id: 9, parentID: 100, accountID: 1, name: "Will filter. Parent not in dataset."),
            
            Category(id: 10, parentID: nil, accountID: 2, name: "root"),
            Category(id: 11, parentID: 10, accountID: 2, name: "A"),
            Category(id: 12, parentID: 10, accountID: 2, name: "B"),
            Category(id: 13, parentID: 11, accountID: 2, name: "1"),
            Category(id: 14, parentID: 11, accountID: 2, name: "2"),
            Category(id: 15, parentID: 11, accountID: 2, name: "3"),
            Category(id: 16, parentID: 12, accountID: 2, name: "4"),
            Category(id: 17, parentID: 16, accountID: 2, name: "First"),
            
            Category(id: 18, parentID: 8, accountID: 3, name: "Will filter. Orphaned"),
        ]
        categories.shuffle()
        let trees = CategoryTree.generateFrom(categories)
        
        let expectedTreeOne = CategoryTree(
            Category(id: 1, parentID: nil, accountID: 1, name: "root"),
            [
                CategoryTree(Category(id: 2, parentID: 1, accountID: 1, name: "A"), []),
                CategoryTree(Category(id: 3, parentID: 1, accountID: 1, name: "B"), []),
                CategoryTree(Category(id: 4, parentID: 1, accountID: 1, name: "C"), [
                    CategoryTree(Category(id: 5, parentID: 4, accountID: 1, name: "1"), [
                        CategoryTree(Category(id: 6, parentID: 5, accountID: 1, name: "First"), []),
                        CategoryTree(Category(id: 7, parentID: 5, accountID: 1, name: "Second"), []),
                    ])
                ])
            ]
        )
        
        let expectedTreeTwo = CategoryTree(
            Category(id: 10, parentID: nil, accountID: 2, name: "root"),
            [
                CategoryTree(Category(id: 11, parentID: 10, accountID: 2, name: "A"), [
                    CategoryTree(Category(id: 13, parentID: 11, accountID: 2, name: "1"), []),
                    CategoryTree(Category(id: 14, parentID: 11, accountID: 2, name: "2"), []),
                    CategoryTree(Category(id: 15, parentID: 11, accountID: 2, name: "3"), []),
                ]),
                CategoryTree(Category(id: 12, parentID: 10, accountID: 2, name: "B"), [
                    CategoryTree(Category(id: 16, parentID: 12, accountID: 2, name: "4"), [
                        CategoryTree(Category(id: 17, parentID: 16, accountID: 2, name: "First"), [])
                    ])
                ])
            ]
        )

        guard trees.count == 2,
        let realTreeOne = trees.first(where: { $0.node.accountID == 1 }),
        let realTreeTwo = trees.first(where: { $0.node.accountID == 2 }) else {
            XCTFail("Expected two trees. A tree for account 1, and account 2.")
            return
        }
        
        XCTAssertEqual(realTreeOne, expectedTreeOne)
        XCTAssertEqual(realTreeTwo, expectedTreeTwo)
    }
    
    func test_sortChildren() {
        let nodeRoot = TimeSDK.Category(id: 1, parentID: nil, accountID: 1, name: "root")
        let nodeA = TimeSDK.Category(id: 2, parentID: 1, accountID: 1, name: "A")
        let nodeB = TimeSDK.Category(id: 3, parentID: 1, accountID: 1, name: "B")
        let nodeC = TimeSDK.Category(id: 4, parentID: 1, accountID: 1, name: "C")
        
        let tree = CategoryTree(nodeRoot, [
            CategoryTree(nodeC, []),
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, [])
        ])
    
        // Starts as specified (C, A, B)
        XCTAssertEqual(tree.children[0].node, nodeC)
        XCTAssertEqual(tree.children[1].node, nodeA)
        XCTAssertEqual(tree.children[2].node, nodeB)
        
        // Sort
        tree.sortChildren()
        
        // Ends Alphabetized
        XCTAssertEqual(tree.children[0].node, nodeA)
        XCTAssertEqual(tree.children[1].node, nodeB)
        XCTAssertEqual(tree.children[2].node, nodeC)
    }
    
    func test_listCategories() {
        let nodeRoot = TimeSDK.Category(id: 1, parentID: nil, accountID: 1, name: "root")
        let nodeA = TimeSDK.Category(id: 2, parentID: 1, accountID: 1, name: "A")
        let nodeB = TimeSDK.Category(id: 3, parentID: 1, accountID: 1, name: "B")
        let nodeC = TimeSDK.Category(id: 4, parentID: 1, accountID: 1, name: "C")
        
        let treeA = CategoryTree(nodeRoot, [
            CategoryTree(nodeA, []),
            CategoryTree(nodeB, []),
            CategoryTree(nodeC, [])
        ])
        
        // Note: parent ids of TimeSDK.Category ignored when building explicitly
        let treeB = CategoryTree(nodeRoot, [
            CategoryTree(nodeA, [
                CategoryTree(nodeC, [])
            ]),
            CategoryTree(nodeB, [])
        ])
        
        let categoriesA = treeA.listCategories()
        let categoriesB = treeB.listCategories()
        
        XCTAssertEqual(categoriesA.count, 4)
        XCTAssertEqual(categoriesA[0], nodeRoot)
        XCTAssertEqual(categoriesA[1], nodeA)
        XCTAssertEqual(categoriesA[2], nodeB)
        XCTAssertEqual(categoriesA[3], nodeC)
        
        XCTAssertEqual(categoriesB.count, 4)
        XCTAssertEqual(categoriesB[0], nodeRoot)
        XCTAssertEqual(categoriesB[1], nodeA)
        XCTAssertEqual(categoriesB[2], nodeC) // Child of A. Children are expanded first
        XCTAssertEqual(categoriesB[3], nodeB)
    }
    
    func test_insert() {
        let nodeRoot = TimeSDK.Category(id: 1, parentID: nil, accountID: 1, name: "root")
        let nodeA = TimeSDK.Category(id: 2, parentID: 1, accountID: 1, name: "A")
        let nodeB = TimeSDK.Category(id: 3, parentID: 1, accountID: 1, name: "B")
        
        let tree = CategoryTree(nodeRoot)
        
        XCTAssertEqual(tree.children.count, 0)
        
        // Inserts node and creates parent reference
        tree.insert(item: nodeB)
        XCTAssertEqual(tree.children.count, 1)
        XCTAssertEqual(tree.children[0].node, nodeB)
        XCTAssertEqual(tree.children[0].parent?.id, nodeRoot.id)
        
        // Inserts at end. Must be re-sorted
        tree.insert(item: nodeA)
        XCTAssertEqual(tree.children.count, 2)
        XCTAssertEqual(tree.children[1].node, nodeA)
        XCTAssertEqual(tree.children[1].parent?.id, nodeRoot.id)
    }
    
    func test_depth() {
        let nodeRoot = TimeSDK.Category(id: 1, parentID: nil, accountID: 1, name: "root")
        let nodeA = TimeSDK.Category(id: 2, parentID: 1, accountID: 1, name: "A")
        let nodeB = TimeSDK.Category(id: 3, parentID: 1, accountID: 1, name: "B")
        let nodeC = TimeSDK.Category(id: 4, parentID: 2, accountID: 1, name: "C")
        
        let tree = CategoryTree(nodeRoot, [
            CategoryTree(nodeA, [
                CategoryTree(nodeC, [])
            ]),
            CategoryTree(nodeB, [])
        ])
        
        XCTAssertEqual(tree.depth, 0)
        XCTAssertEqual(tree.children[0].depth, 1)
        XCTAssertEqual(tree.children[1].depth, 1)
        XCTAssertEqual(tree.children[0].children[0].depth, 2)
    }
    
    func test_expansion() {
        let nodeRoot = TimeSDK.Category(id: 1, parentID: nil, accountID: 1, name: "root")
        let nodeA = TimeSDK.Category(id: 2, parentID: 1, accountID: 1, name: "A")
        let nodeB = TimeSDK.Category(id: 3, parentID: 1, accountID: 1, name: "B")
        let nodeC = TimeSDK.Category(id: 4, parentID: 2, accountID: 1, name: "C")
        
        let treeC = CategoryTree(nodeC, [])
        let treeA = CategoryTree(nodeA, [treeC])
        let treeB = CategoryTree(nodeB, [])
        let tree = CategoryTree(nodeRoot, [treeA, treeB])
        
        // All start collapsed
        XCTAssertEqual(tree.expanded, false)
        XCTAssertEqual(treeA.expanded, false)
        XCTAssertEqual(treeB.expanded, false)
        XCTAssertEqual(treeC.expanded, false)
        
        // Can toggle nodes with children
        tree.toggleExpanded()
        XCTAssertEqual(tree.expanded, true)
        treeA.toggleExpanded()
        XCTAssertEqual(treeA.expanded, true)
        
        // Without children, toggle expanded is ignored
        treeB.toggleExpanded()
        XCTAssertEqual(treeB.expanded, false)
        treeC.toggleExpanded()
        XCTAssertEqual(treeC.expanded, false)
        
        // Can use force to override behavior
        tree.toggleExpanded(forceTo: true)
        XCTAssertEqual(tree.expanded, true)
        tree.toggleExpanded(forceTo: false)
        XCTAssertEqual(tree.expanded, false)
        
        // Overriding behavior does not override rules
        treeC.toggleExpanded(forceTo: true)
        XCTAssertEqual(treeC.expanded, false)
        treeC.toggleExpanded()
        XCTAssertEqual(treeC.expanded, false)
        treeC.toggleExpanded()
        XCTAssertEqual(treeC.expanded, false)
    }
    
    func test_displayRows() {
        let tree = CategoryTree(
            Category(id: 10, parentID: nil, accountID: 2, name: "root"),
            [
                CategoryTree(Category(id: 11, parentID: 10, accountID: 2, name: "A"), [
                    CategoryTree(Category(id: 13, parentID: 11, accountID: 2, name: "1"), []),
                    CategoryTree(Category(id: 14, parentID: 11, accountID: 2, name: "2"), []),
                    CategoryTree(Category(id: 15, parentID: 11, accountID: 2, name: "3"), []),
                ]),
                CategoryTree(Category(id: 12, parentID: 10, accountID: 2, name: "B"), [
                    CategoryTree(Category(id: 16, parentID: 12, accountID: 2, name: "4"), [
                        CategoryTree(Category(id: 17, parentID: 16, accountID: 2, name: "First"), [])
                    ])
                ])
            ]
        )
        
        XCTAssertEqual(tree.numberOfDisplayRows(), 0)
        XCTAssertEqual(tree.numberOfDisplayRows(includeRoot: true), 1)
        XCTAssertEqual(tree.numberOfDisplayRows(overrideExpanded: true), 7)
        XCTAssertEqual(tree.numberOfDisplayRows(overrideExpanded: true, includeRoot: true), 8)
        
        tree.toggleExpanded()
        XCTAssertEqual(tree.numberOfDisplayRows(), 2) // A and B
        
        tree.children[0].toggleExpanded()
        XCTAssertEqual(tree.numberOfDisplayRows(), 2 + 3) // A, B + 1, 2, 3
        
        tree.children[1].toggleExpanded()
        XCTAssertEqual(tree.numberOfDisplayRows(), 2 + 3 + 1) // A, B + 1, 2, 3 + 4
        
        tree.children[1].children[0].toggleExpanded()
        XCTAssertEqual(tree.numberOfDisplayRows(), 2 + 3 + 1 + 1) // A, B + 1, 2, 3 + 4 + First
        
        tree.children[1].toggleExpanded()
        XCTAssertEqual(tree.numberOfDisplayRows(), 2 + 3) // A, B + 1, 2, 3
    }
    
    func test_getChildWithOffset() {
        let cRoot = Category(id: 10, parentID: nil, accountID: 2, name: "root")
            let cA = Category(id: 11, parentID: 10, accountID: 2, name: "A")
                let c1 = Category(id: 13, parentID: 11, accountID: 2, name: "1")
                let c2 = Category(id: 14, parentID: 11, accountID: 2, name: "2")
                let c3 = Category(id: 15, parentID: 11, accountID: 2, name: "3")
            let cB = Category(id: 12, parentID: 10, accountID: 2, name: "B")
                let c4 = Category(id: 16, parentID: 12, accountID: 2, name: "4")
                    let cFirst = Category(id: 17, parentID: 16, accountID: 2, name: "First")
        
        let t1 = CategoryTree(c1, [])
        let t2 = CategoryTree(c2, [])
        let t3 = CategoryTree(c3, [])
        let tA = CategoryTree(cA, [t1, t2, t3])
        
        let tFirst = CategoryTree(cFirst, [])
        let t4 = CategoryTree(c4, [tFirst])
        let tB = CategoryTree(cB, [t4])
        
        let tRoot = CategoryTree(cRoot, [tA, tB])
        
        // Follows Expansion Rules
        XCTAssertEqual(tRoot.getChild(withOffset: 0)?.id, cRoot.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 1)?.id, nil)
        
        tRoot.toggleExpanded(forceTo: true)
        XCTAssertEqual(tRoot.getChild(withOffset: 1)?.id, cA.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 2)?.id, cB.id)
        
        // Works by display order. B moves from index 2 to 5
        tA.toggleExpanded(forceTo: true)
        XCTAssertEqual(tRoot.getChild(withOffset: 1)?.id, cA.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 2)?.id, c1.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 3)?.id, c2.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 4)?.id, c3.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 5)?.id, cB.id)
        
        // Forcing open ignores existing toggle settings
        XCTAssertEqual(tRoot.getChild(withOffset: 7)?.id, nil)
        XCTAssertEqual(tRoot.getChild(withOffset: 7, overrideExpanded: true)?.id, cFirst.id)
        XCTAssertEqual(tRoot.getChild(withOffset: 7)?.id, nil)
        
        tB.toggleExpanded(forceTo: true)
        t4.toggleExpanded(forceTo: true)
        XCTAssertEqual(tRoot.getChild(withOffset: 7)?.id, cFirst.id)
    }
    
    func test_getOffsetWithChild() {
        let cRoot = Category(id: 10, parentID: nil, accountID: 2, name: "root")
        let cA = Category(id: 11, parentID: 10, accountID: 2, name: "A")
        let c1 = Category(id: 13, parentID: 11, accountID: 2, name: "1")
        let c2 = Category(id: 14, parentID: 11, accountID: 2, name: "2")
        let c3 = Category(id: 15, parentID: 11, accountID: 2, name: "3")
        let cB = Category(id: 12, parentID: 10, accountID: 2, name: "B")
        let c4 = Category(id: 16, parentID: 12, accountID: 2, name: "4")
        let cFirst = Category(id: 17, parentID: 16, accountID: 2, name: "First")
        
        let t1 = CategoryTree(c1, [])
        let t2 = CategoryTree(c2, [])
        let t3 = CategoryTree(c3, [])
        let tA = CategoryTree(cA, [t1, t2, t3])
        
        let tFirst = CategoryTree(cFirst, [])
        let t4 = CategoryTree(c4, [tFirst])
        let tB = CategoryTree(cB, [t4])
        
        let tRoot = CategoryTree(cRoot, [tA, tB])
        
        // Follows expansion rules. Will return nil if not displayed
        XCTAssertEqual(tRoot.getOffset(withChild: cRoot), 0)
        XCTAssertEqual(tRoot.getOffset(withChild: cA), nil)
        
        tRoot.toggleExpanded(forceTo: true)
        XCTAssertEqual(tRoot.getOffset(withChild: cA), 1)
        XCTAssertEqual(tRoot.getOffset(withChild: cB), 2)
        
        // Works by display order. B moves from index 2 to 5
        tA.toggleExpanded(forceTo: true)
        XCTAssertEqual(tRoot.getOffset(withChild: cA), 1)
        XCTAssertEqual(tRoot.getOffset(withChild: c1), 2)
        XCTAssertEqual(tRoot.getOffset(withChild: c2), 3)
        XCTAssertEqual(tRoot.getOffset(withChild: c3), 4)
        XCTAssertEqual(tRoot.getOffset(withChild: cB), 5)
        
        // Can also run relative to non-root nodes
        XCTAssertEqual(tA.getOffset(withChild: c1), 1)
        XCTAssertEqual(tA.getOffset(withChild: c2), 2)
        XCTAssertEqual(tA.getOffset(withChild: c3), 3)
        
        // Can ignore toggle settings
        XCTAssertEqual(tRoot.getOffset(withChild: cFirst), nil)
        XCTAssertEqual(tRoot.getOffset(withChild: cFirst, overrideExpanded: true), 7)
        
        // Toggle settings are relative to node down. Settings of parents are ignored
        t4.toggleExpanded(forceTo: true)
        XCTAssertEqual(t4.getOffset(withChild: cFirst), 1)
        XCTAssertEqual(tB.getOffset(withChild: cFirst), nil)
    }
}
