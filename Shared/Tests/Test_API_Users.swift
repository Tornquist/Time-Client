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
    
    static let config = TimeConfig(tokenIdentifier: "test-users-tests")
    static var api: API!
    static var time: Time!
    
    var api: API! { return Test_API_Users.api }
    var time: Time! { return Test_API_Users.time }
    
    override class func setUp() {
        self.api = API(config: self.config)
        self.time = Time(config: self.config, withAPI: self.api)
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
        let email = "\(UUID().uuidString)@time.com"
        let newEmail = "\(UUID().uuidString)@time.com"
        let password = "defaultPassword"
        
        // Configure User
        let createExpectation = self.expectation(description: "createUser")
        var user: User! = nil
        api.createUser(withEmail: email, andPassword: password) { (newUser, error) in
            XCTAssertNotNil(newUser)
            XCTAssertNil(error)
            XCTAssertEqual(newUser?.email, email)
            user = newUser
            
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        guard user != nil else {
            XCTFail("User is required to continue. User not found.")
            return
        }
        
        // Login User
        var loginSucceeded = false
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withEmail: email, andPassword: password) { (token, error) in
            loginSucceeded = token != nil
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        guard loginSucceeded else {
            XCTFail("Successful login required to continue")
            return
        }
        
        // Update User
        var userUpdated = false
        let updateExpectation = self.expectation(description: "updateUser")
        api.updateUser(withID: user.id, setEmail: newEmail) { (user, error) in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            XCTAssertEqual(user?.email, newEmail)
            userUpdated = user?.email == newEmail
            
            updateExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        guard userUpdated else {
            XCTFail("Updated required to re-authenticate with changed credentials")
            return
        }
        
        // Login with new credentials
        let reloginExpectation = self.expectation(description: "loginUser")
        api.getToken(withEmail: newEmail, andPassword: password) { (token, error) in
            XCTAssertNotNil(token)
            reloginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_allowsPasswordToBeChanged() {
        let email = "\(UUID().uuidString)@time.com"
        let password = "defaultPassword"
        let newPassword = "brandNewPassword"
        
        // Configure User
        var user: User! = nil
        let createExpectation = self.expectation(description: "createUser")
        api.createUser(withEmail: email, andPassword: password) { (newUser, error) in
            XCTAssertNotNil(newUser)
            XCTAssertNil(error)
            XCTAssertEqual(newUser?.email, email)
            
            user = newUser
            
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        guard user != nil else {
            XCTFail("User is required to continue. User not found.")
            return
        }
        
        // Login User
        var loginSucceeded = false
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withEmail: email, andPassword: password) { (token, error) in
            loginSucceeded = token != nil
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        guard loginSucceeded else {
            XCTFail("Successful login required to continue")
            return
        }
        
        // Update User
        var userUpdated = false
        let updateExpectation = self.expectation(description: "updateUser")
        api.updateUser(withID: user.id, changePasswordFrom: password, to: newPassword) { (user, error) in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            userUpdated = error == nil
            
            updateExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        guard userUpdated else {
            XCTFail("Update required to re-authenticate with changed credentials")
            return
        }
        
        // Login with new credentials
        let reloginExpectation = self.expectation(description: "loginUser")
        api.getToken(withEmail: email, andPassword: newPassword) { (token, error) in
            XCTAssertNotNil(token)
            reloginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
