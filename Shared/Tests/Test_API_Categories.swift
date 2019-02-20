//
//  Test_API_Categories.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_API_Categories: XCTestCase {
    static var tokenTag = "test-categories-tests"
    static var api: API!
    static var time: Time!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    static var accounts: [Account] = []
    static var categories: [TimeSDK.Category] = []
    
    var tokenTag: String { return Test_API_Categories.tokenTag }
    var api: API! { return Test_API_Categories.api }
    var time: Time! { return Test_API_Categories.time }
    
    var email: String { return Test_API_Categories.email }
    var password: String { return Test_API_Categories.password }
    
    var accounts: [Account] {
        get { return Test_API_Categories.accounts }
        set {
            Test_API_Categories.accounts = newValue
        }
    }
    var categories: [TimeSDK.Category] {
        get { return Test_API_Categories.categories }
        set {
            Test_API_Categories.categories = newValue
        }
    }
    
    override class func setUp() {
        Test_API_Categories.api = API()
        Test_API_Categories.time = Time(withAPI: Test_API_Categories.api, andTokenIdentifier: self.tokenTag)
    }
    
    override func setUp() {
        guard api.token == nil else { return }
        
        let createExpectation = self.expectation(description: "createUser")
        api.createUser(withEmail: email, andPassword: password) { (user, error) in
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: email, andPassword: password) { (user, error) in
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_0_startsWithNoAccountsAndNoCategories() {
        self.continueAfterFailure = false
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(categories)
            XCTAssertEqual(categories!.count, 0)
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let accountExpectation = self.expectation(description: "getAccounts")
        api.getAccounts { (accounts, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(accounts)
            XCTAssertEqual(accounts!.count, 0)
            accountExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_1_createsARootCategoryWithEachNewAccount() {
        self.continueAfterFailure = false
        
        var newAccount: Account?
        let accountExpectation = self.expectation(description: "createAccount")
        api.createAccount { (account, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(account)
            newAccount = account
            accountExpectation.fulfill()
            
            if newAccount != nil {
                self.accounts.append(newAccount!)
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            XCTAssertNil(error)
            XCTAssertEqual(categories?.count ?? 0, 1)
            
            if let category = categories?[0] {
                XCTAssertEqual(category.accountID, newAccount!.id)
                XCTAssertEqual(category.name, "root")
                XCTAssertNil(category.parentID)
                
                self.categories.append(category)
            } else {
                XCTFail("Expected a category to be created")
            }
            
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_2_creatingAChildCategory() {
        self.continueAfterFailure = false
        
        guard self.categories.count == 1 else {
            XCTFail("Test requires a single category to exist")
            return
        }
        
        let parent = self.categories[0]
        
        let createCategoryExpectation = self.expectation(description: "postCategory")
        api.createCategory(withName: "A", under: parent) { (newCategory, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(parent.accountID, newCategory?.accountID)
            XCTAssertEqual(newCategory?.name, "A")
            
            if newCategory != nil { self.categories.append(newCategory!) }
            
            createCategoryExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            XCTAssertNil(error)
            XCTAssertEqual(categories?.count ?? 0, 2)
            
            if let a = categories?[0], let b = categories?[1] {
                if a.parentID == nil {
                    XCTAssertEqual(b.parentID!, a.id)
                } else {
                    XCTAssertEqual(a.parentID!, b.id)
                }
            }
            
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_3_createASiblingCategory() {
        self.continueAfterFailure = false
        
        guard self.categories.count == 2 else {
            XCTFail("Test requires two categories to exist")
            return
        }
        
        guard let parent = self.categories.first(where: { $0.parentID == nil }) else {
            XCTFail("Unable to find parent category")
            return
        }
        
        let createCategoryExpectation = self.expectation(description: "postCategory")
        api.createCategory(withName: "B", under: parent) { (newCategory, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(parent.accountID, newCategory?.accountID)
            XCTAssertEqual(newCategory?.name, "B")
            
            if newCategory != nil { self.categories.append(newCategory!) }
            
            createCategoryExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            XCTAssertNil(error)
            XCTAssertEqual(categories?.count ?? 0, 3)
            
            categories?.forEach({ (c) in
                if c.parentID == nil {
                    XCTAssertEqual(c.name, "root")
                } else {
                    XCTAssertEqual(c.parentID!, parent.id)
                }
            })
            
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_4_allowsCategoriesToBeMoved() {
        self.continueAfterFailure = false
        
        guard let root = self.categories.first(where: { $0.name == "root" }),
            let categoryA = self.categories.first(where: { $0.name == "A" }),
            let categoryB = self.categories.first(where: { $0.name == "B" }) else {
                XCTFail("Prerequisite categories not found")
                return
        }
        
        XCTAssertNil(root.parentID)
        XCTAssertEqual(root.id, categoryA.parentID)
        XCTAssertEqual(root.id, categoryB.parentID)
    
        let categoriesExpectation = self.expectation(description: "moveCategory")
        api.moveCategory(categoryA, toParent: categoryB) { (updatedCategory, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedCategory)
    
            XCTAssertEqual(categoryA.id, updatedCategory?.id)
            XCTAssertEqual(categoryA.name, updatedCategory?.name)
            XCTAssertEqual(categoryA.accountID, updatedCategory?.accountID)
            XCTAssertEqual(categoryB.id, updatedCategory?.parentID)
            
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_5_allowsMovingCategoriesBetweenAccounts() {
        self.continueAfterFailure = false
        
        // Create a second account
        let accountExpectation = self.expectation(description: "createAccount")
        api.createAccount { (account, error) in
            if account != nil { self.accounts.append(account!) }
            accountExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Fetch new root
        var completeCategories: [TimeSDK.Category] = []
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            completeCategories.append(contentsOf: categories ?? [])
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(self.accounts.count, 2)
        XCTAssertEqual(completeCategories.count, (1 + 2) + (1))
        
        // Move category
        guard
            let firstRoot = completeCategories.first(where: { $0.parentID == nil && $0.accountID == self.accounts[0].id }),
            let secondRoot = completeCategories.first(where: { $0.parentID == nil && $0.accountID == self.accounts[1].id }),
            let categoryB = completeCategories.first(where: { $0.name == "B" })
            else {
                XCTFail("Missing required root nodes")
                return
        }
        
        XCTAssertEqual(categoryB.accountID, firstRoot.accountID)

        var newB: TimeSDK.Category? = nil
        let moveAccountExpectation = self.expectation(description: "moveCategory")
        api.moveCategory(categoryB, toParent: secondRoot) { (updatedCategory, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedCategory)
            
            newB = updatedCategory
            moveAccountExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Verify Returned Change (Does not return tree)
        guard newB != nil else { XCTFail(); return }
        
        XCTAssertEqual(newB!.accountID, secondRoot.accountID)
        XCTAssertEqual(newB!.parentID, secondRoot.id)
        XCTAssertEqual(categoryB.id, newB!.id)
        XCTAssertEqual(categoryB.name, newB!.name)
        
        // Verify Moved Children
        let freshCategories = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            
            if let freshA = categories?.first(where: { $0.name == "A" }),
                let freshB = categories?.first(where: { $0.name == "B" }) {
                
                XCTAssertEqual(freshA.accountID, secondRoot.accountID)
                XCTAssertEqual(freshB.accountID, secondRoot.accountID)
                
                XCTAssertEqual(freshB.parentID, secondRoot.id)
                XCTAssertEqual(freshA.parentID, freshB.id)
            } else {
                XCTFail("Unable to find category A and B")
            }
            
            if categories != nil {
                self.categories.removeAll()
                self.categories.append(contentsOf: categories!)
            }
            
            freshCategories.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_6_rejectsMovingCategoriesWithMismatchedParentAndAccountIDs() {
        self.continueAfterFailure = false
        
        guard
            let firstRoot = self.categories.first(where: { $0.parentID == nil && $0.accountID == self.accounts[0].id }),
            let secondRoot = self.categories.first(where: { $0.parentID == nil && $0.accountID == self.accounts[1].id }),
            let categoryA = self.categories.first(where: { $0.name == "A" }),
            let categoryB = self.categories.first(where: { $0.name == "B" })
            else {
                XCTFail("Missing required root nodes")
                return
        }
        
        // Verify starting situation
        XCTAssertEqual(categoryB.parentID, secondRoot.id)
        XCTAssertEqual(categoryA.parentID, categoryB.id)
        
        let badCategory = TimeSDK.Category(
            id: firstRoot.id,
            parentID: nil,
            accountID: secondRoot.accountID,
            name: "root"
        )
    
        let moveExpectation = self.expectation(description: "moveCategory")
        api.moveCategory(categoryA, toParent: badCategory) { (updatedCategory, error) in
            let timeError = error as? TimeError
            XCTAssertEqual(timeError, TimeError.httpFailure("400"))
            
            moveExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
