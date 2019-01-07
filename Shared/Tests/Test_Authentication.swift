//
//  Test_Authentication.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/7/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
import Time

class Test_Authentication: XCTestCase {
    
    override func setUp() { }
    
    override func tearDown() { }
    
    func test_1_uauthenticated() {
        let isAuthenticated = Time.shared.isAuthenticated()
        XCTAssertFalse(isAuthenticated)
    }
    
    func test_2_authenticateWithInvalidCredentials() {
        let expectation = self.expectation(description: "getToken")
        
        Time.shared.authenticate(email: "test@test.com", password: "madeUpPassword") { (error) in
            XCTAssertNotNil(error)
            
            switch error! {
            case TimeError.httpFailure("401"):
                XCTAssertTrue(true)
            default:
                XCTAssertFalse(true, "Unexpected error returned")
                break
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_3_stillUnauthenticated() {
        let isAuthenticated = Time.shared.isAuthenticated()
        XCTAssertFalse(isAuthenticated)
    }
    
    func test_4_authenticateWithValidCredentials() {
        let expectation = self.expectation(description: "getToken")
        
        Time.shared.authenticate(email: "test@test.com", password: "defaultPassword") { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_5_authenticated() {
        let isAuthenticated = Time.shared.isAuthenticated()
        XCTAssertTrue(isAuthenticated)
    }
}
