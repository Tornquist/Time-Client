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
}
