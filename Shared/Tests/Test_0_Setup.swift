//
//  Test_0_Setup.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/2/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_0_Setup: XCTestCase {
    
    func test_createDefaultUserIfNeeded() {
        let api = API()
        
        let email = "test@test.com"
        let password = "defaultPassword"
        
        var userExists = false
        
        // Attempt to log user in
        let loginUserExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: email, andPassword: password) { (token, error) in
            userExists = token != nil
            loginUserExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        guard !userExists else { return }

        // Attempt to create user if needed
        let createUserExpectation = self.expectation(description: "createUser")
        API.shared.createUser(withEmail: email, andPassword: password) { (user, error) in
            createUserExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
