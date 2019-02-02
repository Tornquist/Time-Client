//
//  Test_API_Tokens.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/9/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import Time

class Test_API_Tokens: XCTestCase {
    
    override func setUp() { }
    
    override func tearDown() { }
    
    func test_getToken_validCredentials() {
        let expectation = self.expectation(description: "getToken")
        
        API.shared.getToken(withUsername: "test@test.com", andPassword: "defaultPassword") { (token, error) in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_getToken_invalidCredentials() {
        let expectation = self.expectation(description: "getToken")
        
        API.shared.getToken(withUsername: "test@test.com", andPassword: "madeUpPassword") { (token, error) in
            XCTAssertNil(token)
            if let trueError = error as? TimeError {
                XCTAssertEqual(trueError, TimeError.httpFailure("401"))
            } else {
                XCTAssert(false, "Unexpected error returned")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_refreshToken_validRefresh() {
        self.continueAfterFailure = false
        
        var startingToken: Token? = nil
        let getExpectation = self.expectation(description: "getToken")
        API.shared.getToken(withUsername: "test@test.com", andPassword: "defaultPassword") { (authToken, error) in
            startingToken = authToken
            
            XCTAssertNotNil(authToken)
            getExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let refreshExpectation = self.expectation(description: "refreshToken")
        API.shared.refreshToken() { (refreshedToken, error) in
            XCTAssertNotNil(refreshedToken)
            XCTAssertNil(error)
            
            XCTAssertNotEqual(startingToken!.token, refreshedToken!.token)
            refreshExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_refreshToken_invalidRefresh() {
        let expectation = self.expectation(description: "refreshToken")
        
        let token = Token(
            userID: 1,
            creation: Date(),
            expiration: Date(),
            token: "abcd",
            refresh: "notReal"
        )
        API.shared.token = token
        
        API.shared.refreshToken() { (token, error) in
            XCTAssertNil(token)
            if let trueError = error as? TimeError {
                XCTAssertEqual(trueError, TimeError.httpFailure("400")) // Made up token not found
            } else {
                XCTAssert(false, "Unexpected error returned")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
