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
    
    var time: Time!
    
    override func setUp() {
        self.time = Time()
    }
    
    override func tearDown() { }
    
    func test_initialAuthentication() {
        let isAuthenticated = time.isAuthenticated()
        XCTAssertFalse(isAuthenticated)
    }
    
    func test_unauthenticatedWithInvalidCredentials() {
        let startsUnauthenticated = time.isAuthenticated()
        XCTAssertFalse(startsUnauthenticated)
        
        let expectation = self.expectation(description: "getToken")
        
        time.authenticate(username: "test@test.com", password: "madeUpPassword") { (error) in
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
        
        let endsUnauthenticated = time.isAuthenticated()
        XCTAssertFalse(endsUnauthenticated)
    }
    
    func test_authenticateWithValidCredentials() {
        let startsUnauthenticated = time.isAuthenticated()
        XCTAssertFalse(startsUnauthenticated)
        
        let expectation = self.expectation(description: "getToken")
        
        time.authenticate(username: "test@test.com", password: "defaultPassword") { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        let endsAuthenticated = time.isAuthenticated()
        XCTAssertTrue(endsAuthenticated)
    }
}
