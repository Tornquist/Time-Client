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
    
    static var tokenTag = "test-users-tests"
    static var api: API!
    static var time: Time!
    
    var tokenTag: String { return Test_API_Users.tokenTag }
    var api: API! { return Test_API_Users.api }
    var time: Time! { return Test_API_Users.time }
    
    override class func setUp() {
        Test_API_Users.api = API()
        Test_API_Users.time = Time(withAPI: Test_API_Users.api, andTokenIdentifier: self.tokenTag)
    }
    
    override func setUp() { }
    
    override func tearDown() { }
    
    func test_createUser_success() {
        let expectation = self.expectation(description: "createUser")
        
        let uuid = UUID().uuidString
        let email = "\(uuid)@time.com"
        let password = "defaultPassword"
        
        API.shared.createUser(withEmail: email, andPassword: password) { (newUser, error) in
            XCTAssertNotNil(newUser)
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
    
    func test_allowsEmailToBeChanged() {
        self.continueAfterFailure = false
        
        let email = "\(UUID().uuidString)@time.com"
        let newEmail = "\(UUID().uuidString)@time.com"
        let password = "defaultPassword"
        
        // Configure User
        let createExpectation = self.expectation(description: "createUser")

        var user: User! = nil
        api.createUser(withEmail: email, andPassword: password) { (newUser, error) in
            XCTAssertNotNil(newUser)
            XCTAssertNil(error)
            user = newUser
            
            XCTAssertEqual(newUser?.email, email)
            
            createExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        // Login User
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: email, andPassword: password) { (token, error) in
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Update User
        let updateExpectation = self.expectation(description: "updateUser")
        api.updateUser(withID: user.id, setEmail: newEmail) { (user, error) in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            XCTAssertEqual(user?.email, newEmail)
            
            updateExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Login with new credentials
        let reloginExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: newEmail, andPassword: password) { (token, error) in
            XCTAssertNotNil(token)
            reloginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_allowsPasswordToBeChanged() {
        self.continueAfterFailure = false
        
        let email = "\(UUID().uuidString)@time.com"
        let password = "defaultPassword"
        let newPassword = "brandNewPassword"
        
        // Configure User
        let createExpectation = self.expectation(description: "createUser")
        
        var user: User! = nil
        api.createUser(withEmail: email, andPassword: password) { (newUser, error) in
            XCTAssertNotNil(newUser)
            XCTAssertNil(error)
            user = newUser
            
            XCTAssertEqual(newUser?.email, email)
            
            createExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        // Login User
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: email, andPassword: password) { (token, error) in
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Update User
        let updateExpectation = self.expectation(description: "updateUser")
        api.updateUser(withID: user.id, changePasswordFrom: password, to: newPassword) { (user, error) in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            updateExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Login with new credentials
        let reloginExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: email, andPassword: newPassword) { (token, error) in
            XCTAssertNotNil(token)
            reloginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
