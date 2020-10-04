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
    
    static let config = TimeConfig()
    var config: TimeConfig { return Test_0_Setup.config }
    
    func test_0_createDefaultUserIfNeeded() {
        let api = API(config: self.config)
        
        let email = "test@test.com"
        let password = "defaultPassword"
        
        var userExists = false
        
        // Attempt to log user in
        let loginUserExpectation = self.expectation(description: "loginUser")
        api.getToken(withEmail: email, andPassword: password) { (token, error) in
            userExists = token != nil
            loginUserExpectation.fulfill()
        }
        waitForExpectations(timeout: 15, handler: nil)
        
        guard !userExists else { return }

        // Attempt to create user if needed
        let createUserExpectation = self.expectation(description: "createUser")
        API.shared.createUser(withEmail: email, andPassword: password) { (user, error) in
            createUserExpectation.fulfill()
        }
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func test_1_configureSharedTime() {
        let startingURL = Time.shared.api.baseURL
        let overrideURL = "http://localhost:9999"
        
        // Starts with a URL (default or cached), and no config
        XCTAssertNil(Time.shared.config.serverURL)
        XCTAssertEqual(Time.shared.api.baseURL, startingURL)
        
        // Maintains the same URL when configuring with no explicit override
        Time.configureShared(TimeConfig())
        XCTAssertNil(Time.shared.config.serverURL)
        XCTAssertEqual(Time.shared.api.baseURL, startingURL)
                
        // Allows configuration of the shared singleton through Time.configureShared
        Time.configureShared(TimeConfig(serverURL: overrideURL))
        
        XCTAssertEqual(Time.shared.config.serverURL, overrideURL)
        XCTAssertEqual(Time.shared.api.baseURL, overrideURL)
        
        // Allows the singleton to be set back to the original URL
        Time.configureShared(TimeConfig(serverURL: startingURL))
        XCTAssertEqual(Time.shared.config.serverURL, startingURL)
        XCTAssertEqual(Time.shared.api.baseURL, startingURL)
    }
}
