//
//  Test_API_Users.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/10/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_API_Users: XCTestCase {
    
    override func setUp() { }
    
    override func tearDown() { }
    
    func test_createUser_success() {
        let expectation = self.expectation(description: "createUser")
        
        let uuid = UUID().uuidString
        let email = "\(uuid)@time.com"
        let password = "defaultPassword"
        
        API.shared.createUser(withEmail: email, andPassword: password) { (user, error) in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_createUser_rejectsDuplicate() {
        let expectation = self.expectation(description: "createUser")
        
        let email = "test@test.com"
        let password = "defaultPassword"
        
        API.shared.createUser(withEmail: email, andPassword: password) { (user, error) in
            XCTAssertNil(user)
            if let trueError = error as? TimeError {
                XCTAssertEqual(trueError, TimeError.httpFailure("409"))
            } else {
                XCTAssert(false, "Unexpected error returned")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_createUser_rejectsBadPassword() {
        let expectation = self.expectation(description: "createUser")
        
        let email = "test@test.com"
        let password = "l"
        
        API.shared.createUser(withEmail: email, andPassword: password) { (user, error) in
            XCTAssertNil(user)
            if let trueError = error as? TimeError {
                XCTAssertEqual(trueError, TimeError.httpFailure("400"))
            } else {
                XCTAssert(false, "Unexpected error returned")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_createUser_rejectsBadEmail() {
        let expectation = self.expectation(description: "createUser")
        
        let email = "notAnEmail"
        let password = "defaultPassword"
        
        API.shared.createUser(withEmail: email, andPassword: password) { (user, error) in
            XCTAssertNil(user)
            if let trueError = error as? TimeError {
                XCTAssertEqual(trueError, TimeError.httpFailure("400"))
            } else {
                XCTAssert(false, "Unexpected error returned")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
