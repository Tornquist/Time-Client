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

        guard trees.count == 2 else {
            XCTFail("Expected two trees")
            return
        }
        
        guard let treeOne = trees.first(where: { $0.node.accountID == 1 }) else {
            XCTFail("Expected a tree for account 1")
            return
        }
        
        XCTAssertEqual(treeOne.node.accountID, 1)
        XCTAssertEqual(treeOne.node.name, "root")
        XCTAssertEqual(treeOne.children.count, 3)
        
        let oneOne = treeOne.children[0]
        XCTAssertEqual(oneOne.id, 2)
        XCTAssertEqual(oneOne.node.name, "A")
        XCTAssertEqual(oneOne.children.count, 0)
        
        let oneTwo = treeOne.children[1]
        XCTAssertEqual(oneTwo.id, 3)
        XCTAssertEqual(oneTwo.node.name, "B")
        XCTAssertEqual(oneTwo.children.count, 0)
        
        let oneThree = treeOne.children[2]
        XCTAssertEqual(oneThree.id, 4)
        XCTAssertEqual(oneThree.node.name, "C")
        XCTAssertEqual(oneThree.children.count, 1)
        
        let oneThreeOne = oneThree.children[0]
        XCTAssertEqual(oneThreeOne.id, 5)
        XCTAssertEqual(oneThreeOne.node.name, "1")
        XCTAssertEqual(oneThreeOne.children.count, 2)
        
        let oneThreeOneOne = oneThreeOne.children[0]
        XCTAssertEqual(oneThreeOneOne.id, 6)
        XCTAssertEqual(oneThreeOneOne.node.name, "First")
        XCTAssertEqual(oneThreeOneOne.children.count, 0)
        
        let oneThreeOneTwo = oneThreeOne.children[1]
        XCTAssertEqual(oneThreeOneTwo.id, 7)
        XCTAssertEqual(oneThreeOneTwo.node.name, "Second")
        XCTAssertEqual(oneThreeOneTwo.children.count, 0)
        
        guard let treeTwo = trees.first(where: { $0.node.accountID == 2 }) else {
            XCTFail("Expected a tree for account 2")
            return
        }
        
        XCTAssertEqual(treeTwo.node.accountID, 2)
        XCTAssertEqual(treeTwo.node.name, "root")
        XCTAssertEqual(treeTwo.children.count, 2)
        
        let twoOne = treeTwo.children[0]
        XCTAssertEqual(twoOne.id, 11)
        XCTAssertEqual(twoOne.node.name, "A")
        XCTAssertEqual(twoOne.children.count, 3)
        
        let twoTwo = treeTwo.children[1]
        XCTAssertEqual(twoTwo.id, 12)
        XCTAssertEqual(twoTwo.node.name, "B")
        XCTAssertEqual(twoTwo.children.count, 1)
        
        let twoOneOne = twoOne.children[0]
        XCTAssertEqual(twoOneOne.id, 13)
        XCTAssertEqual(twoOneOne.node.name, "1")
        XCTAssertEqual(twoOneOne.children.count, 0)
        
        let twoOneTwo = twoOne.children[1]
        XCTAssertEqual(twoOneTwo.id, 14)
        XCTAssertEqual(twoOneTwo.node.name, "2")
        XCTAssertEqual(twoOneTwo.children.count, 0)
        
        let twoOneThree = twoOne.children[2]
        XCTAssertEqual(twoOneThree.id, 15)
        XCTAssertEqual(twoOneThree.node.name, "3")
        XCTAssertEqual(twoOneThree.children.count, 0)
        
        let twoTwoOne = twoTwo.children[0]
        XCTAssertEqual(twoTwoOne.id, 16)
        XCTAssertEqual(twoTwoOne.node.name, "4")
        XCTAssertEqual(twoTwoOne.children.count, 1)
        
        let twoTwoOneOne = twoTwoOne.children[0]
        XCTAssertEqual(twoTwoOneOne.id, 17)
        XCTAssertEqual(twoTwoOneOne.node.name, "First")
        XCTAssertEqual(twoTwoOneOne.children.count, 0)
    }
}
