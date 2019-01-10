//
//  Test_API_Users.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/10/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import Time

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
            XCTAssertNotNil(error)
            
            switch error! {
            case TimeError.httpFailure("409"):
                XCTAssertTrue(true)
            default:
                XCTAssertFalse(true, "Unexpected error returned")
                break
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
            XCTAssertNotNil(error)
            
            switch error! {
            case TimeError.httpFailure("400"):
                XCTAssertTrue(true)
            default:
                XCTAssertFalse(true, "Unexpected error returned")
                break
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
            XCTAssertNotNil(error)
            
            switch error! {
            case TimeError.httpFailure("400"):
                XCTAssertTrue(true)
            default:
                XCTAssertFalse(true, "Unexpected error returned")
                break
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
