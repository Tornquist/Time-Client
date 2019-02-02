//
//  Test_Authentication.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/7/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import Time

class Test_Authentication: XCTestCase {
    
    static var tokenTag = "test-authentication-tests"
    static var api: API!
    static var time: Time!
    
    var tokenTag: String { return Test_Authentication.tokenTag }
    var api: API! { return Test_Authentication.api }
    var time: Time! { return Test_Authentication.time }
    
    override class func setUp() {
        Test_Authentication.api = API()
        Test_Authentication.time = Time(withAPI: Test_Authentication.api, andTokenIdentifier: self.tokenTag)
    }
    
    func test_0_clearAnyExistingToken() {
        // Note: This allows individual tests to be re-run without a global clear at start
        _ = TokenStore.deleteToken(withTag: self.tokenTag)
    }
    
    func test_1_initializeWithNoTokenReturnsTokenNotFound() {
        self.continueAfterFailure = false
        
        let expectation = self.expectation(description: "authentication")
        
        self.time.initialize { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error as! TimeError, TimeError.tokenNotFound())
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_2_authenticateSetsToken() {
        self.continueAfterFailure = false
        
        let username = "test@test.com"
        let password = "defaultPassword"
        
        let expectation = self.expectation(description: "authentication")
        self.time.authenticate(username: username, password: password) { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_3_authenticatedTokenExpiresInFuture() {
        guard let expiration = self.api.token?.expiration else {
            XCTFail("Token expiration not found")
            return
        }
        
        let now = Date()
        
        XCTAssertLessThan(now, expiration)
    }
    
    func test_4_callingInitializeWithATokenDoesNothing() {
        let expectation = self.expectation(description: "authentication")
        
        let tokenStringBefore = self.api.token?.token
        self.time.initialize { (error) in
            XCTAssertNil(error)
            let tokenStringAfter = self.api.token?.token
            
            XCTAssertEqual(tokenStringBefore, tokenStringAfter)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_5_initializeRetreivesAVAlidToken() {
        // Note: Dependent on previous tests
        let tokenStringBefore = self.api.token?.token
        
        // Clear API token for true refresh
        self.api.token = nil
        
        let expectation = self.expectation(description: "authentication")
        self.time.initialize { (error) in
            XCTAssertNil(error)
            let tokenStringAfter = self.api.token?.token
            
            XCTAssertEqual(tokenStringBefore, tokenStringAfter)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_6_initializeWithAnExpiredTokenRefreshes() {
        self.continueAfterFailure = false
        
        guard let startingToken = TokenStore.getToken(withTag: self.tokenTag) else {
            XCTAssertTrue(false, "Test conditions not met")
            return
        }
        let newToken = Token(
            userID: startingToken.userID,
            creation: startingToken.creation,
            expiration: Date(timeIntervalSinceReferenceDate: 0),
            token: startingToken.token,
            refresh: startingToken.refresh
        )
        let storedExpiredToken = TokenStore.storeToken(newToken, withTag: self.tokenTag)
        XCTAssertTrue(storedExpiredToken)
        
        // Clear API token for true refresh
        self.api.token = nil
        
        let expectation = self.expectation(description: "authentication")
        self.time.initialize { (error) in
            XCTAssertNil(error)
            
            XCTAssertNotNil(self.api.token!)
            XCTAssertNotEqual(newToken.token, self.api.token!.token)
            XCTAssertLessThan(newToken.expiration, self.api.token!.expiration)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_7_initializeWithAnInvalidRefreshTokenRejects() {
        self.continueAfterFailure = false
        
        guard let startingToken = TokenStore.getToken(withTag: self.tokenTag) else {
            XCTAssertTrue(false, "Test conditions not met")
            return
        }
        let newToken = Token(
            userID: startingToken.userID,
            creation: startingToken.creation,
            expiration: Date(timeIntervalSinceReferenceDate: 0),
            token: startingToken.token,
            refresh: "This is not a real token"
        )
        let storedExpiredToken = TokenStore.storeToken(newToken, withTag: self.tokenTag)
        XCTAssertTrue(storedExpiredToken)
        
        // Clear API token for true refresh
        self.api.token = nil
        
        let expectation = self.expectation(description: "authentication")
        self.time.initialize { (error) in
            XCTAssertNotNil(error)
            
            XCTAssertEqual(error as! TimeError, TimeError.unableToRefreshToken())
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
