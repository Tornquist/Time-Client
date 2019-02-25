//
//  Test_API_Entries.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/24/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_API_Entries: XCTestCase {
    static var tokenTag = "test-entries-tests"
    static var api: API!
    static var time: Time!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    static var accounts: [Account] = []
    static var categories: [TimeSDK.Category] = []
    
    var tokenTag: String { return Test_API_Entries.tokenTag }
    var api: API! { return Test_API_Entries.api }
    var time: Time! { return Test_API_Entries.time }
    
    var email: String { return Test_API_Entries.email }
    var password: String { return Test_API_Entries.password }
    
    static var account: Account! = nil
    var account: Account {
        get { return Test_API_Entries.account }
        set { Test_API_Entries.account = newValue }
    }
    
    static var category: TimeSDK.Category! = nil
    var category: TimeSDK.Category {
        get { return Test_API_Entries.category }
        set { Test_API_Entries.category = newValue }
    }
    
    override class func setUp() {
        Test_API_Entries.api = API()
        Test_API_Entries.time = Time(withAPI: Test_API_Entries.api, andTokenIdentifier: self.tokenTag)
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
        
        let accountExpectation = self.expectation(description: "createAccount")
        api.createAccount { (account, error) in
            if account != nil {
                self.account = account!
            } else {
                XCTFail("Expected an account to be created")
            }
            accountExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            if categories != nil && categories!.count > 0 {
                self.category = categories![0]
            } else {
                XCTFail("Expected a category to exist")
            }
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_0_startsWithNoEntries() {
        let expectation = self.expectation(description: "entries")
        api.getEntries { (entries, error) in
            XCTAssertNotNil(entries)
            XCTAssertEqual(entries?.count, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_1_recordingAnEvent() {
        let expectation = self.expectation(description: "entries")
        api.recordEvent(for: self.category) { (entry, error) in
            XCTAssertNotNil(entry)
            if entry != nil {
                XCTAssertEqual(entry!.type, EntryType.event)
                XCTAssertEqual(entry!.categoryID, self.category.id)
                XCTAssertNotNil(entry!.startedAt)
                XCTAssertNil(entry!.endedAt)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_2_rejectsStoppingARangeWhenNoneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .stop) { (entry, error) in
            XCTAssertEqual(error as? TimeError, TimeError.httpFailure("400"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_3_allowsStartingARangeWhenNoneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .start) { (entry, error) in
            XCTAssertNotNil(entry)
            if entry != nil {
                XCTAssertEqual(entry?.type, EntryType.range)
                XCTAssertNotNil(entry?.startedAt)
                XCTAssertNil(entry?.endedAt)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_4_rejectsStartingARangeWhenOneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .start) { (entry, error) in
            XCTAssertEqual(error as? TimeError, TimeError.httpFailure("400"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_5_allowsStoppingARangeWhenOneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .stop) { (entry, error) in
            XCTAssertNotNil(entry)
            if entry != nil {
                XCTAssertEqual(entry?.type, EntryType.range)
                XCTAssertNotNil(entry?.startedAt)
                XCTAssertNotNil(entry?.endedAt)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}