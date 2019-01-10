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
    
    func test_refreshToken_validRefresh() {
        let expectation = self.expectation(description: "refreshToken")
        
        API.shared.getToken(withUsername: "test@test.com", andPassword: "defaultPassword") { (token, error) in
            XCTAssertNotNil(token)
            
            API.shared.refreshToken(with: token!) { (token, error) in
                XCTAssertNotNil(token)
                XCTAssertNil(error)
                
                expectation.fulfill()
            }
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
        
        API.shared.refreshToken(with: token) { (token, error) in
            XCTAssertNil(token)
            XCTAssertNotNil(error)
            
            switch error! {
            case TimeError.httpFailure("400"): // Made up token not found
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
