//
//  Test_Store.swift
//  Shared
//
//  Created by Nathan Tornquist on 5/6/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_Store: XCTestCase {
    static var tokenTag = "test-store-tests"
    static var api: API!
    static var time: Time!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    static var sharedEntry: Entry? = nil
    
    var tokenTag: String { return Test_Store.tokenTag }
    var api: API! { return Test_Store.api }
    var time: Time! { return Test_Store.time }
    
    var email: String { return Test_Store.email }
    var password: String { return Test_Store.password }
    
    static var store: Store! = nil
    var store: Store {
        get { return Test_Store.store }
        set { Test_Store.store = newValue }
    }
    
    override class func setUp() {
        Test_Store.api = API()
        Test_Store.time = Time(withAPI: Test_Store.api, andTokenIdentifier: self.tokenTag)
    }
    
    override func setUp() {
        guard api.token == nil else { return }
        
        let create = self.expectation(description: "createUser")
        api.createUser(withEmail: email, andPassword: password) { _,_ in create.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)
        
        let login = self.expectation(description: "loginUser")
        api.getToken(withEmail: email, andPassword: password) { _,_ in login.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)
        
        let aA = self.expectation(description: "accountA")
        api.createAccount { _,_ in aA.fulfill() }
        let aB = self.expectation(description: "accountB")
        api.createAccount { _,_ in aB.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Starting Configuration
        // rootA
        // rootB
    }
    
    func test_00_initializingAStore() {
        self.store = Store(api: self.api)
        
        XCTAssertEqual(self.store.categories.count, 0)
        XCTAssertEqual(self.store.categoryTrees.count, 0)
        XCTAssertEqual(self.store.accountIDs.count, 0)
    }
    
    func test_01_fetchingData() {
        self.store = Store(api: self.api)
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        self.store.getCategories { (categories, error) in
            if error != nil { XCTFail("Expected getCategories to succeed") }
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(self.store.categories.count, 2)
        XCTAssertEqual(self.store.accountIDs.count, 2)
        XCTAssertEqual(self.store.categoryTrees.count, 2)
    }
    
    func test_02_softFetchingDataSkipsNetwork() {
        let startTime = CFAbsoluteTimeGetCurrent()
        var timeElapsed: CFAbsoluteTime! = nil
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        self.store.getCategories { (categories, error) in
            if error != nil { XCTFail("Expected getCategories to succeed") }
            timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertEqual(timeElapsed, 0, accuracy: 0.0001)
    }
    
    func test_03_canForceRefreshData() {
        let startTime = CFAbsoluteTimeGetCurrent()
        var timeElapsed: CFAbsoluteTime! = nil
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        self.store.getCategories(refresh: true) { (categories, error) in
            if error != nil { XCTFail("Expected getCategories to succeed") }
            timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Expect 2-100ms
        XCTAssertGreaterThan(timeElapsed, 0.002)
        XCTAssertLessThan(timeElapsed, 0.100)
    }
    
    
    // After test 4
    // rootA
    //   A
    //      1
    //         Z
    //      2
    //   B
    //      3
    //   C
    // rootB
    //   D
    //   E
    func test_04_addingCategories() {
        self.continueAfterFailure = false
        
        guard self.store.accountIDs.count == 2 else {
            XCTFail("Unexpected number of account IDs")
            return
        }
        let accountIDA = self.store.accountIDs.sorted()[0]
        let accountIDB = self.store.accountIDs.sorted()[1]
        guard
            let treeA = self.store.categoryTrees[accountIDA],
            let treeB = self.store.categoryTrees[accountIDB]
            else {
                XCTFail("Expected trees for both accounts")
                return
        }
        
        let rootA = treeA.node
        let rootB = treeB.node
        
        // Creating First Level
        
        var categoryA: TimeSDK.Category! = nil
        var categoryB: TimeSDK.Category! = nil
        var categoryC: TimeSDK.Category! = nil
        var categoryD: TimeSDK.Category! = nil
        var categoryE: TimeSDK.Category! = nil
        
        let createA = self.expectation(description: "createA")
        self.store.addCategory(withName: "A", to: rootA) { (s, new) in
            if s && new != nil { categoryA = new }
            else { XCTFail("Creating category A failed") }
            createA.fulfill()
        }
        
        let createB = self.expectation(description: "createB")
        self.store.addCategory(withName: "B", to: rootA) { (s, new) in
            if s && new != nil { categoryB = new }
            else { XCTFail("Creating category B failed") }
            createB.fulfill()
        }
        
        let createC = self.expectation(description: "createA")
        self.store.addCategory(withName: "C", to: rootA) { (s, new) in
            if s && new != nil { categoryC = new }
            else { XCTFail("Creating category C failed") }
            createC.fulfill()
        }
        
        let createD = self.expectation(description: "createD")
        self.store.addCategory(withName: "D", to: rootB) { (s, new) in
            if s && new != nil { categoryD = new }
            else { XCTFail("Creating category D failed") }
            createD.fulfill()
        }
        
        let createE = self.expectation(description: "createE")
        self.store.addCategory(withName: "E", to: rootB) { (s, new) in
            if s && new != nil { categoryE = new }
            else { XCTFail("Creating category E failed") }
            createE.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNotNil(categoryA)
        XCTAssertNotNil(categoryB)
        XCTAssertNotNil(categoryC)
        XCTAssertNotNil(categoryD)
        XCTAssertNotNil(categoryE)
        
        XCTAssertEqual(rootA.id, categoryA.parentID)
        XCTAssertEqual(rootA.id, categoryB.parentID)
        XCTAssertEqual(rootA.id, categoryC.parentID)
        XCTAssertEqual(rootB.id, categoryD.parentID)
        XCTAssertEqual(rootB.id, categoryE.parentID)
        
        XCTAssertEqual(treeA.children.count, 3)
        XCTAssertEqual(treeB.children.count, 2)
        
        XCTAssertEqual(treeA.children[0].node, categoryA)
        XCTAssertEqual(treeA.children[1].node, categoryB)
        XCTAssertEqual(treeA.children[2].node, categoryC)
        
        XCTAssertEqual(treeB.children[0].node, categoryD)
        XCTAssertEqual(treeB.children[1].node, categoryE)
        
        // Creating Second Level
        
        var category1: TimeSDK.Category! = nil
        var category2: TimeSDK.Category! = nil
        var category3: TimeSDK.Category! = nil
        
        let create1 = self.expectation(description: "create1")
        self.store.addCategory(withName: "1", to: categoryA) { (s, new) in
            if s && new != nil { category1 = new }
            else { XCTFail("Creating category 1 failed") }
            create1.fulfill()
        }
        
        let create2 = self.expectation(description: "create2")
        self.store.addCategory(withName: "2", to: categoryA) { (s, new) in
            if s && new != nil { category2 = new }
            else { XCTFail("Creating category 2 failed") }
            create2.fulfill()
        }
        
        let create3 = self.expectation(description: "create3")
        self.store.addCategory(withName: "3", to: categoryB) { (s, new) in
            if s && new != nil { category3 = new }
            else { XCTFail("Creating category 3 failed") }
            create3.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNotNil(category1)
        XCTAssertNotNil(category2)
        XCTAssertNotNil(category3)
        
        XCTAssertEqual(categoryA.id, category1.parentID)
        XCTAssertEqual(categoryA.id, category2.parentID)
        XCTAssertEqual(categoryB.id, category3.parentID)
        
        XCTAssertEqual(treeA.children[0].children.count, 2)
        XCTAssertEqual(treeA.children[1].children.count, 1)
        
        XCTAssertEqual(treeA.children[0].children[0].node, category1)
        XCTAssertEqual(treeA.children[0].children[1].node, category2)
        XCTAssertEqual(treeA.children[1].children[0].node, category3)
        
        // Creating Third Level
        
        var categoryZ: TimeSDK.Category! = nil
        
        let createZ = self.expectation(description: "createZ")
        self.store.addCategory(withName: "Z", to: category1) { (s, new) in
            if s && new != nil { categoryZ = new }
            else { XCTFail("Creating category Z failed") }
            createZ.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNotNil(categoryZ)
        XCTAssertEqual(category1.id, categoryZ.parentID)
        XCTAssertEqual(treeA.children[0].children[0].children.count, 1)
        XCTAssertEqual(treeA.children[0].children[0].children[0].node, categoryZ)
    }
    
    // After test 5
    // rootA
    //   A
    //      2
    //      New Name
    //         Z
    //   B
    //      3
    //   C
    // rootB
    //   D
    //   E
    func test_05_renamingCategories() {
        guard self.store.accountIDs.count == 2,
            let tree = self.store.categoryTrees[
                self.store.accountIDs.sorted()[0]
            ],
            tree.children.count >= 0 &&
            tree.children[0].children.count >= 0
        else {
            XCTFail("Expected prerequisites to be met")
            return
        }
        
        let categoryTree = tree.children[0].children[0]
        let category = categoryTree.node
        let existingName = category.name
        let newName = "New Name"
        
        // Not required, but useful for tracking position and structure of tree for dependent tests
        XCTAssertEqual(existingName, "1")
        
        let renameExpectation = self.expectation(description: "rename")
        self.store.renameCategory(category, to: newName) { (success) in
            XCTAssert(success)
            renameExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNotEqual(categoryTree.node.name, existingName)
        XCTAssertEqual(categoryTree.node.name, newName)
    }
    
    func test_06_canMove() {
        guard self.store.accountIDs.count == 2,
            let rootA = self.store.categoryTrees[self.store.accountIDs.sorted()[0]],
            let rootB = self.store.categoryTrees[self.store.accountIDs.sorted()[1]]
        else {
            XCTFail("Expected prerequisites to be met")
            return
        }
        
        // Verify structure
        guard rootA.children.count == 3 && rootB.children.count == 2 else {
            XCTFail("Unexpected number of children")
            return
        }
        
        let treeA = rootA.children[0]
        let treeB = rootA.children[1]
        let treeC = rootA.children[2]
        let treeD = rootB.children[0]
        let treeE = rootB.children[1]

        guard treeA.children.count == 2 && treeB.children.count == 1 else {
            XCTFail("Unexpected number of children")
            return
        }
        
        let tree1 = treeA.children[0] // Renamed in previous test
        let tree2 = treeA.children[1]
        let tree3 = treeB.children[0]
        
        guard tree1.children.count == 1 else {
            XCTFail("Unexpected number of children")
            return
        }
        
        let treeZ = tree1.children[0]
        
        // Evaluate moving
        
        // Cannot move to current parent
        XCTAssertFalse(self.store.canMove(treeA.node, to: rootA.node))
        XCTAssertFalse(self.store.canMove(treeB.node, to: rootA.node))
        XCTAssertFalse(self.store.canMove(treeC.node, to: rootA.node))
        XCTAssertFalse(self.store.canMove(treeD.node, to: rootB.node))
        XCTAssertFalse(self.store.canMove(treeE.node, to: rootB.node))
        XCTAssertFalse(self.store.canMove(tree1.node, to: treeA.node))
        XCTAssertFalse(self.store.canMove(tree2.node, to: treeA.node))
        XCTAssertFalse(self.store.canMove(tree3.node, to: treeB.node))
        XCTAssertFalse(self.store.canMove(treeZ.node, to: tree1.node))
        
        // Cannot move to self
        XCTAssertFalse(self.store.canMove(treeA.node, to: treeA.node))
        XCTAssertFalse(self.store.canMove(treeB.node, to: treeB.node))
        XCTAssertFalse(self.store.canMove(treeC.node, to: treeC.node))
        XCTAssertFalse(self.store.canMove(treeD.node, to: treeD.node))
        XCTAssertFalse(self.store.canMove(treeE.node, to: treeE.node))
        XCTAssertFalse(self.store.canMove(tree1.node, to: tree1.node))
        XCTAssertFalse(self.store.canMove(tree2.node, to: tree2.node))
        XCTAssertFalse(self.store.canMove(tree3.node, to: tree3.node))
        XCTAssertFalse(self.store.canMove(treeZ.node, to: treeZ.node))
        
        // Cannot move to child of self
        XCTAssertFalse(self.store.canMove(treeA.node, to: tree1.node))
        XCTAssertFalse(self.store.canMove(treeA.node, to: tree2.node))
        XCTAssertFalse(self.store.canMove(treeA.node, to: treeZ.node))
        XCTAssertFalse(self.store.canMove(treeB.node, to: tree3.node))
        
        // All other options are supported
        let keys = [treeA, treeB, treeC, treeD, treeE, tree1, tree2, tree3, treeZ]
        var options: [Int: [CategoryTree]] = [:]
        options[treeA.id] = [treeB, tree3, treeC, treeD, treeE, rootB]
        options[treeB.id] = [treeA, tree1, treeZ, tree2, rootB, treeD, treeE]
        options[treeC.id] = [treeA, tree1, treeZ, tree2, treeB, tree3, rootB, treeD, treeE]
        options[treeD.id] = [rootA, treeA, tree1, treeZ, tree2, treeB, tree3, treeC, treeE]
        options[treeE.id] = [rootA, treeA, tree1, treeZ, tree2, treeB, tree3, treeC, treeD]
        options[tree1.id] = [rootA, tree2, treeB, tree3, treeC, rootB, treeD, treeE]
        options[tree2.id] = [rootA, tree1, treeZ, treeB, tree3, treeC, rootB, treeD, treeE]
        options[tree3.id] = [rootA, treeA, tree1, treeZ, tree2, treeC, rootB, treeD, treeE]
        options[treeZ.id] = [rootA, treeA, tree2, treeB, tree3, treeC, rootB, treeD, treeE]
        
        options.forEach { (data) in
            let key = data.key
            let values = data.value
            guard let tree = keys.first(where: { key == $0.id }) else {
                XCTFail("Could not find node for category")
                return
            }
            
            values.forEach({ (destination) in
                XCTAssert(self.store.canMove(tree.node, to: destination.node), "\(tree.node.name) -> \(destination.node.name)")
            })
        }
    }
    
    // After test 7
    // rootA
    //   B
    //      3
    //   C
    // rootB
    //   D
    //     A
    //        2
    //        New Name
    //           Z
    //   E
    func test_07_movingCategories() {
        self.continueAfterFailure = false
        
        guard self.store.accountIDs.count == 2,
            let rootA = self.store.categoryTrees[self.store.accountIDs.sorted()[0]],
            let rootB = self.store.categoryTrees[self.store.accountIDs.sorted()[1]],
            rootA.children.count >= 1 && rootA.children[0].node.name == "A" &&
            rootB.children.count >= 1 && rootB.children[0].node.name == "D"
            else {
                XCTFail("Expected prerequisites to be met")
                return
        }
        
        let treeA = rootA.children[0]
        let treeD = rootB.children[0]
        
        let moveExpectation = self.expectation(description: "move")
        self.store.moveCategory(treeA.node, to: treeD.node) { (success) in
            XCTAssert(success)
            moveExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Removed from rootA children
        XCTAssertEqual(rootA.children.count, 2)
        XCTAssertEqual(rootA.children[0].node.name, "B")
        XCTAssertEqual(rootA.children[1].node.name, "C")
        
        // No impact on top-level rootB
        XCTAssertEqual(rootB.children.count, 2)
        XCTAssertEqual(rootB.children[0].node.name, "D")
        XCTAssertEqual(rootB.children[1].node.name, "E")
        
        // Added as child to D
        XCTAssertEqual(rootB.children[0].children.count, 1)
        XCTAssertEqual(rootB.children[0].children[0].node.name, "A")
        
        // Updated references
        XCTAssert(treeA.parent === treeD)
        XCTAssertEqual(treeA.node.parentID, treeD.id)
        XCTAssertEqual(treeA.node.accountID, treeD.node.accountID)
        
        let movedChildren = treeA.listCategories()
        movedChildren.forEach({ XCTAssertEqual($0.accountID, treeD.node.accountID) })
    }
    
    // After test 8
    // rootA
    //   C
    // rootB
    //   B
    //      3
    //   D
    //     A
    //        2
    //        New Name
    //           Z
    //   E
    func test_08_movingCategoriesResorts() {
        self.continueAfterFailure = false
        
        guard self.store.accountIDs.count == 2,
            let rootA = self.store.categoryTrees[self.store.accountIDs.sorted()[0]],
            let rootB = self.store.categoryTrees[self.store.accountIDs.sorted()[1]],
            rootA.children.count >= 0 && rootA.children[0].node.name == "B" &&
            rootB.children.count >= 0 && rootB.children[0].node.name == "D"
            else {
                XCTFail("Expected prerequisites to be met")
                return
        }
        
        let treeB = rootA.children[0]
        
        let moveExpectation = self.expectation(description: "move")
        self.store.moveCategory(treeB.node, to: rootB.node) { (success) in
            XCTAssert(success)
            moveExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(treeB.parent === rootB)
        XCTAssertEqual(rootB.children.count, 3)
        XCTAssertEqual(rootB.children[0].node, treeB.node)
    }
    
    // After test 9
    // rootA
    //   C
    // rootB
    //   B
    //      3
    //   D
    //      2
    //      New Name
    //         Z
    //   E
    func test_09_deletingCategoriesAndNotChildren() {
        self.continueAfterFailure = false
        
        guard self.store.accountIDs.count == 2,
            let rootA = self.store.categoryTrees[self.store.accountIDs.sorted()[0]],
            let rootB = self.store.categoryTrees[self.store.accountIDs.sorted()[1]],
            rootA.children.count >= 1 && rootA.children[0].node.name == "C" &&
            rootB.children.count >= 2 && rootB.children[0].node.name == "B"
                                      && rootB.children[1].node.name == "D" &&
            rootB.children[1].children.count >= 0 && rootB.children[1].children[0].node.name == "A" &&
            rootB.children[1].children[0].children.count >= 2
            else {
                XCTFail("Expected prerequisites to be met")
                return
        }
        
        let treeD = rootB.children[1]
        let treeA = treeD.children[0]
        let tree1 = treeA.children[0]
        let tree2 = treeA.children[1]
        
        let deleteID = treeA.node.id
        
        let deleteExpectation = self.expectation(description: "delete")
        self.store.deleteCategory(withID: deleteID, andChildren: false) { (success) in
            XCTAssert(success)
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(treeD.children.count, 2)
        XCTAssert(tree1.parent === treeD)
        XCTAssert(tree2.parent === treeD)
        
        let categoryA = self.store.categories.first(where: { $0.id == deleteID})
        XCTAssertNil(categoryA)
    }
    
    // After test 10
    // rootA
    //   C
    // rootB
    //   B
    //      3
    //   E
    func test_10_deletingCategoriesAndChildren() {
        self.continueAfterFailure = false
        
        guard self.store.accountIDs.count == 2,
            let rootA = self.store.categoryTrees[self.store.accountIDs.sorted()[0]],
            let rootB = self.store.categoryTrees[self.store.accountIDs.sorted()[1]] else {
            XCTFail("Missing account trees"); return
        }
        guard rootA.children.count >= 1 && rootA.children[0].node.name == "C" else {
            XCTFail("Unexpected rootA structure"); return
        }
        guard rootA.children.count >= 1 && rootA.children[0].node.name == "C" else {
            XCTFail("Unexpected rootB structure"); return
        }
        guard rootB.children.count >= 3 && rootB.children[0].node.name == "B"
            && rootB.children[1].node.name == "D" else {
            XCTFail("Unexpected rootB -> D structure"); return
        }
        guard rootB.children[1].children.count >= 2
            && rootB.children[1].children[0].node.name == "2"
            && rootB.children[1].children[1].node.name == "New Name" else { // Renamed earlier
            XCTFail("Unexpected D -> 2 and D -> New Name structure"); return
        }
        guard rootB.children[1].children[1].children.count > 0 else {
            XCTFail("Missing child of 'New Name'"); return
        }
        
        let treeD = rootB.children[1]
        let tree2 = treeD.children[0]
        let treeNewName = treeD.children[1]
        let treeZ = treeNewName.children[0]
        
        let deleteID = treeD.node.id
        let removedIDs = [deleteID, treeNewName.id, tree2.id, treeZ.id]
        
        let deleteExpectation = self.expectation(description: "delete")
        self.store.deleteCategory(withID: deleteID, andChildren: true) { (success) in
            XCTAssert(success)
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(rootB.children.count, 2)
        
        let persistedObjects = removedIDs.compactMap({ removedID in
            return self.store.categories.first(where: { $0.id == removedID })
        })
        XCTAssertEqual(persistedObjects.count, 0)
    }
}
