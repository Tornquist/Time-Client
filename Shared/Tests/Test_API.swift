//
//  Test_API.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/16/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_API: XCTestCase {
    
    static var tokenTag = "test-api-tests"
    static var api: API!
    static var time: Time!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    static var accounts: [Account] = []
    static var categories: [TimeSDK.Category] = []
    
    var tokenTag: String { return Test_API.tokenTag }
    var api: API! { return Test_API.api }
    var time: Time! { return Test_API.time }
    
    var email: String { return Test_API.email }
    var password: String { return Test_API.password }
    
    override class func setUp() {
        Test_API.api = API()
        Test_API.time = Time(withAPI: Test_API.api, andTokenIdentifier: self.tokenTag)
    }
    
    override func setUp() {
        guard api.token == nil else { return }
        
        let createExpectation = self.expectation(description: "createUser")
        api.createUser(withEmail: email, andPassword: password) { (user, error) in
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withUsername: email, andPassword: password) { (user, error) in
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_rejectsAllRequestsWithBadBaseURL() {
        let newAPI = API()
        newAPI.baseURL = "/\\"
        
        let expectation = self.expectation(description: "badURL")
        newAPI.timeRequest(path: "/endpoint", method: .GET, body: nil, encoding: nil, authorized: false, completion: { (user: User?, error: Error?) in
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToSendRequest("Cannot build URL"))
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_rejectsEncodingAndNoBody() {
        let expectation = self.expectation(description: "encodingMismatch")
        api.timeRequest(path: "/endpoint", method: .GET, body: nil, encoding: .json, authorized: false, completion: { (user: User?, error: Error?) in
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToSendRequest("Mismatched body and encoding"))
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_rejectsBodyAndNoEncoding() {
        let expectation = self.expectation(description: "encodingMismatch")
        api.timeRequest(path: "/endpoint", method: .GET, body: ["a": "b"], encoding: nil, authorized: false, completion: { (user: User?, error: Error?) in
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToSendRequest("Mismatched body and encoding"))
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_encodingAndMethodMismatch() {
        let expectation = self.expectation(description: "encodingMismatch")
        api.timeRequest(path: "/accounts", method: .GET, body: ["a": "b"], encoding: .json, authorized: true, completion: { (accounts: [Account]?, error: Error?) in
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToSendRequest("Encoding not supported for method type"))
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_rejectsNullInFormURLEncoded() {
        let expectation = self.expectation(description: "formURLEncodingMismatch")
        let emptyString: String? = nil
        api.timeRequest(path: "/accounts", method: .POST, body: ["a": emptyString as Any], encoding: .formUrlEncoded, authorized: true, completion: { (account: Account?, error: Error?) in

            XCTAssertEqual(error as? TimeError, TimeError.unableToSendRequest("x-www-form-urlencoded requires string values"))
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_rejectsNonStringValuesInFormURLEncoded() {
        let expectation = self.expectation(description: "formURLEncodingMismatch")
        api.timeRequest(path: "/accounts", method: .POST, body: ["a": 1], encoding: .formUrlEncoded, authorized: true, completion: { (account: Account?, error: Error?) in
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToSendRequest("x-www-form-urlencoded requires string values"))
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_failsMismatchedResponseTypeAndCompletionType() {
        let expectation = self.expectation(description: "typeMismatch")
        api.timeRequest(path: "/accounts", method: .POST, body: nil, encoding: nil, authorized: true, completion: { (accounts: [Account]?, error: Error?) in
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToDecodeResponse())
            expectation.fulfill()
        }, sideEffects: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // MARK: - Handle Failed Access
    
    func test_failedTokenSuccessfulRefresh() {
        let expectation = self.expectation(description: "autoRefreshToken")
        
        // Configure real request
        let url = URL(string: self.api.baseURL + "/accounts")!
        var sideEffectsCalled = false
        
        let request = APIRequest(
            url: url,
            method: "GET",
            authorized: true,
            headers: ["Content-Type":"application/json"],
            body: nil,
            completion: { (accounts: [Account]?, error: Error?) in
                XCTAssertNotNil(accounts)
                XCTAssertNil(error)
                expectation.fulfill()
            },
            sideEffects: { (accounts: [Account]?) in
                sideEffectsCalled = true
            }
        )
        
        // Load request in failed queue
        request.failed = true
        request.failureCount = 1
        self.api.queue.store(request: request)
        
        // Trigger token refresh and monitor token change
        let startingToken = self.api.token?.token
        api.handleFailedAccess()
        waitForExpectations(timeout: 5, handler: nil)
        
        let endingToken = self.api.token?.token
        
        XCTAssertNotEqual(startingToken, endingToken)
        XCTAssertTrue(sideEffectsCalled)
    }
    
    // Destructive test: run last
    func test_z_failedTokenFailedRefresh() {
        let expectation = self.expectation(description: "autoRefreshToken")
        
        // Configure real request
        let url = URL(string: self.api.baseURL + "/accounts")!
        var sideEffectsCalled = false
        
        let request = APIRequest(
            url: url,
            method: "GET",
            authorized: true,
            headers: ["Content-Type":"application/json"],
            body: nil,
            completion: { (accounts: [Account]?, error: Error?) in
                XCTAssertNil(accounts)
                XCTAssertNotNil(error)
                expectation.fulfill()
            },
            sideEffects: { (accounts: [Account]?) in
                sideEffectsCalled = true
            }
        )
        
        // Load request in failed queue
        request.failed = true
        request.failureCount = 1
        self.api.queue.store(request: request)
        
        // Trigger token refresh and monitor token change
        let startingToken = self.api.token?.token
        self.api.token?.refresh = "ASDF" // Break token so refresh fails
        api.handleFailedAccess()
        waitForExpectations(timeout: 5, handler: nil)
        
        let endingToken = self.api.token?.token
        
        // No refresh occurred
        XCTAssertEqual(startingToken, endingToken)
        // Side effects only called on success
        XCTAssertFalse(sideEffectsCalled)
    }
}
