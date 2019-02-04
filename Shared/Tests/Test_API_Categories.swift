//
//  Test_API_Categories.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import Time

class Test_API_Categories: XCTestCase {
    
    static var tokenTag = "test-categories-tests"
    static var api: API!
    static var time: Time!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    var tokenTag: String { return Test_API_Categories.tokenTag }
    var api: API! { return Test_API_Categories.api }
    var time: Time! { return Test_API_Categories.time }
    
    var email: String { return Test_API_Categories.email }
    var password: String { return Test_API_Categories.password }
    
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
            } else {
                XCTFail("Expected a category to be created")
            }
            
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
