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
    
    static var sharedEntry: Entry? = nil
    
    var tokenTag: String { return Test_API_Entries.tokenTag }
    var api: API! { return Test_API_Entries.api }
    var time: Time! { return Test_API_Entries.time }
    
    var email: String { return Test_API_Entries.email }
    var password: String { return Test_API_Entries.password }
    
    var timezone: String { return TimeZone.autoupdatingCurrent.identifier }
    
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
        api.getToken(withEmail: email, andPassword: password) { (user, error) in
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
    
    func test_00_startsWithNoEntries() {
        let expectation = self.expectation(description: "entries")
        api.getEntries { (entries, error) in
            XCTAssertNotNil(entries)
            XCTAssertEqual(entries?.count, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_01_recordingAnEvent() {
        let expectation = self.expectation(description: "entries")
        api.recordEvent(for: self.category) { (entry, error) in
            XCTAssertNotNil(entry)
            if entry != nil {
                XCTAssertEqual(entry!.type, EntryType.event)
                XCTAssertEqual(entry!.categoryID, self.category.id)
                XCTAssertNotNil(entry!.startedAt)
                XCTAssertEqual(entry!.startedAtTimezone, self.timezone)
                XCTAssertNil(entry!.endedAt)
                XCTAssertNil(entry!.endedAtTimezone)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_02_rejectsStoppingARangeWhenNoneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .stop) { (entry, error) in
            XCTAssertEqual(error as? TimeError, TimeError.httpFailure("400"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_03_allowsStartingARangeWhenNoneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .start) { (entry, error) in
            XCTAssertNotNil(entry)
            if entry != nil {
                XCTAssertEqual(entry!.type, EntryType.range)
                XCTAssertNotNil(entry!.startedAt)
                XCTAssertEqual(entry!.startedAtTimezone, self.timezone)
                XCTAssertNil(entry!.endedAt)
                XCTAssertNil(entry!.endedAtTimezone)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_04_rejectsStartingARangeWhenOneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .start) { (entry, error) in
            XCTAssertEqual(error as? TimeError, TimeError.httpFailure("400"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_05_allowsStoppingARangeWhenOneOpen() {
        let expectation = self.expectation(description: "entries")
        api.updateRange(for: self.category, with: .stop) { (entry, error) in
            XCTAssertNotNil(entry)
            if entry != nil {
                XCTAssertEqual(entry!.type, EntryType.range)
                XCTAssertNotNil(entry!.startedAt)
                XCTAssertEqual(entry!.startedAtTimezone, self.timezone)
                XCTAssertNotNil(entry!.endedAt)
                XCTAssertEqual(entry!.endedAtTimezone, self.timezone)
            }
            
            Test_API_Entries.sharedEntry = entry
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_06_allowsEntriesToBeLoadedByID() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 5. Missing entry")
            return
        }
        
        let expectation = self.expectation(description: "entry")
        api.getEntry(withID: se.id) { (e, error) in
            XCTAssertEqual(se.id, e?.id)
            XCTAssertEqual(se.type, e?.type)
            XCTAssertEqual(se.categoryID, e?.categoryID)
            XCTAssertEqual(se.startedAt, e?.startedAt)
            XCTAssertEqual(
                se.endedAt?.timeIntervalSinceReferenceDate ?? -100,
                e?.endedAt?.timeIntervalSinceReferenceDate ?? -200,
                accuracy: 1.0
            )
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_07_allowsEntryTypeToBeUpdated() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 5. Missing entry")
            return
        }
        
        XCTAssertNotNil(se.endedAt)
        XCTAssertNotNil(se.endedAtTimezone)
        
        let expectation = self.expectation(description: "entry")
        api.updateEntry(with: se.id, setType: .event) { (updatedEvent, error) in
            XCTAssertEqual(se.id, updatedEvent?.id)
            XCTAssertEqual(updatedEvent?.type, EntryType.event)
            XCTAssertEqual(se.categoryID, updatedEvent?.categoryID)
            XCTAssertEqual(se.startedAt, updatedEvent?.startedAt)
            XCTAssertNil(updatedEvent?.endedAt)
            XCTAssertNil(updatedEvent?.endedAtTimezone)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_08_allowsStartedAtToBeUpdated() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 5. Missing entry")
            return
        }
        
        let newStart = Date()
        
        let expectation = self.expectation(description: "entry")
        api.updateEntry(with: se.id, setStartedAt: newStart) { (updatedEvent, error) in
            XCTAssertEqual(se.id, updatedEvent?.id)
            XCTAssertEqual(updatedEvent?.type, EntryType.event)
            XCTAssertEqual(se.categoryID, updatedEvent?.categoryID)
            XCTAssertEqual(
                updatedEvent?.startedAt.timeIntervalSinceReferenceDate ?? -100,
                newStart.timeIntervalSinceReferenceDate,
                accuracy: 1.0
            )
            XCTAssertNil(updatedEvent?.endedAt)
            
            Test_API_Entries.sharedEntry = updatedEvent
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_09_allowsStartedAtTimezoneToBeUpdated() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 8. Missing entry")
            return
        }
        
        XCTAssertEqual(se.startedAtTimezone, self.timezone)
        
        let newStartTimezone = "America/Indiana/Indianapolis"
        
        let expectation = self.expectation(description: "entry")
        api.updateEntry(with: se.id, setStartedAtTimezone: newStartTimezone) { (updatedEvent, error) in
            XCTAssertEqual(se.id, updatedEvent?.id)
            XCTAssertEqual(updatedEvent?.type, EntryType.event)
            XCTAssertEqual(se.categoryID, updatedEvent?.categoryID)
            XCTAssertEqual(
                se.startedAt.timeIntervalSinceReferenceDate,
                updatedEvent?.startedAt.timeIntervalSinceReferenceDate ?? -200,
                accuracy: 1.0
            )
            XCTAssertEqual(updatedEvent?.startedAtTimezone, newStartTimezone)
            XCTAssertNil(updatedEvent?.endedAt)
            XCTAssertNil(updatedEvent?.endedAtTimezone)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_10_allowsMultipleFieldsToBeChanged() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 8. Missing entry")
            return
        }
        
        let newEnd = Date()
        let newEndTimezone = "America/New_York"
        
        let expectation = self.expectation(description: "entry")
        api.updateEntry(with: se.id, setType: .range, setEndedAt: newEnd, setEndedAtTimezone: newEndTimezone) { (updatedEvent, error) in
            XCTAssertEqual(se.id, updatedEvent?.id)
            XCTAssertEqual(updatedEvent?.type, EntryType.range)
            XCTAssertEqual(se.categoryID, updatedEvent?.categoryID)
            XCTAssertEqual(
                updatedEvent?.endedAt?.timeIntervalSinceReferenceDate ?? -100,
                newEnd.timeIntervalSinceReferenceDate,
                accuracy: 1.0
            )
            XCTAssertEqual(updatedEvent?.endedAtTimezone, newEndTimezone)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_11_allowsCategoryToBeChanged() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 8. Missing entry")
            return
        }
        
        var parent: TimeSDK.Category! = nil
        let categoriesExpectation = self.expectation(description: "getCategories")
        api.getCategories { (categories, error) in
            parent = categories?[0]
            categoriesExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        guard parent != nil else {
            XCTFail("Expected parent to exist")
            return
        }
        
        var child: TimeSDK.Category! = nil
        let createCategoryExpectation = self.expectation(description: "createCategory")
        api.createCategory(withName: "Child", under: parent!) { (newCategory, error) in
            child = newCategory
            createCategoryExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        guard child != nil else {
            XCTFail("Expected child to exist")
            return
        }
        
        let expectation = self.expectation(description: "entry")
        api.updateEntry(with: se.id, setCategory: child) { (updatedEvent, error) in
            XCTAssertEqual(child.id, updatedEvent?.categoryID)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_12_deletingEntries() {
        guard let se = Test_API_Entries.sharedEntry else {
            XCTFail("Dependent on test 8. Missing entry")
            return
        }
        
        let deleteExpectation = self.expectation(description: "deleteEntry")
        api.deleteEntry(withID: se.id) { error in
            XCTAssertNil(error)
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let confirmDeletion = self.expectation(description: "confirmEntry")
        api.getEntry(withID: se.id) { (entry, error) in
            XCTAssertEqual(error as? TimeError, TimeError.httpFailure("400"))
            confirmDeletion.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
