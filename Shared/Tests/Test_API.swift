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
    
    static var api: API!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    static var accounts: [Account] = []
    static var categories: [TimeSDK.Category] = []
    
    var api: API! { return Test_API.api }
    
    var email: String { return Test_API.email }
    var password: String { return Test_API.password }
    
    override class func setUp() {
        self.api = API()
    }
    
    override func setUp() {
        guard api.token == nil else { return }
        
        let createExpectation = self.expectation(description: "createUser")
        api.createUser(withEmail: email, andPassword: password) { (user, error) in
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let loginExpectation = self.expectation(description: "loginUser")
        api.getToken(withEmail: email, andPassword: password) { (user, error) in
            loginExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_rejectsAllRequestsWithBadBaseURL() {
        let newAPI = API(baseURL: "/\\")
        
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
            
            XCTAssertEqual(error as? TimeError, TimeError.unableToDecodeResponse)
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
    
    // MARK: - URL Configuration Tests
    
    func test_defaultURLIsCorrect() {
        let newAPI = API()
        XCTAssertEqual(newAPI.baseURL, "http://localhost:8000")
    }
    
    func test_canSetCustomURL() {
        let myURLOverride = "https://myCustomSubdomain.myCustomDomain.com"
        let newAPI = API(baseURL: myURLOverride)
        XCTAssertEqual(newAPI.baseURL, myURLOverride)
    }
    
    func test_canChangeURLFromDefault() {
        let newAPI = API()
        XCTAssertEqual(newAPI.baseURL, "http://localhost:8000")
        
        let newURL = "https://myCustomSubdomain.myCustomDomain.com"
        let didChange = newAPI.set(url: newURL)
        
        XCTAssertTrue(didChange)
        XCTAssertEqual(newAPI.baseURL, newURL)
    }
    
    func test_canChangeURLFromOverride() {
        let baseURL = "https://myCustomSubdomain.myCustomDomain.com"
        let newURL = "https://www.myOtherCustomDomain.com"
        
        let newAPI = API(baseURL: baseURL)
        XCTAssertEqual(newAPI.baseURL, baseURL)
        
        let didChange = newAPI.set(url: newURL)
        
        XCTAssertTrue(didChange)
        XCTAssertEqual(newAPI.baseURL, newURL)
    }
    
    func test_returnsDidChangeOnFirstChange() {
        let newAPI = API()
        XCTAssertEqual(newAPI.baseURL, "http://localhost:8000")
        
        let newURL = "https://www.myOtherCustomDomain.com"
        let didChange = newAPI.set(url: newURL)
        
        XCTAssertTrue(didChange)
        XCTAssertEqual(newAPI.baseURL, newURL)
        
        let didChangeAgain = newAPI.set(url: newURL)
        XCTAssertFalse(didChangeAgain)
        XCTAssertEqual(newAPI.baseURL, newURL)
    }
    
    func test_sharedAPIUsesCaching() {
        let keyName = "time-api-configuration-server-url-override"

        // Force reset
        let api = API.shared
        _ = api.set(url: "https://default.domain.com")
        
        // Test
        let newURL = "https://otherSubdomain.newDomain.com"
        
        let startingStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertNotEqual(startingStoredValue, newURL)
        
        let didUpdate = api.set(url: newURL)
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(api.baseURL, newURL)
        
        let newStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(newStoredValue, newURL)
        
        // Return to safe (for any tests using API.shared)
        _ = api.set(url: "http://localhost:8000")
    }
    
    func test_sharedAPISupportsFullTimeConfigConfiguration() {
        let keyName = "time-api-configuration-server-url-override"

        // Force reset
        API.configureShared(TimeConfig(serverURL: "https://default.domain.com"))
        
        // Test
        let newURL = "https://otherSubdomain.newDomain.com"
        API.configureShared(TimeConfig(serverURL: newURL))
        
        let storedValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(storedValue, newURL)
        XCTAssertEqual(API.shared.baseURL, newURL)
        
        // Return to safe (for any tests using API.shared)
        _ = api.set(url: "http://localhost:8000")
    }
    
    func test_cachingBehaviorIsDisabledByDefaultForNewAPIObjects() {
        let keyName = "time-api-configuration-server-url-override"

        let startingStoredValue = UserDefaults.standard.string(forKey: keyName)
        
        let newURL = "https://\(UUID.init().uuidString).com"
        let newAPI = API()
        let didUpdate = newAPI.set(url: newURL)
        
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(newAPI.baseURL, newURL)
        
        let endingStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(startingStoredValue, endingStoredValue)
        XCTAssertNotEqual(endingStoredValue, newURL)
    }
    
    func test_cachingBehaviorCanBeEnabledForCustomObjects() {
        let keyName = "time-api-configuration-server-url-override"

        // Force reset
        let api = API(enableURLCachingBehavior: true)
        _ = api.set(url: "https://default.domain.com")
        
        // Test
        let newURL = "https://otherSubdomain.newDomain.com"
        
        let startingStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertNotEqual(startingStoredValue, newURL)
        
        let didUpdate = api.set(url: newURL)
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(api.baseURL, newURL)
        
        let newStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(newStoredValue, newURL)
        
        // Return to safe (for any tests using API.shared)
        _ = api.set(url: "http://localhost:8000")
    }
    
    func test_cachingBehaviorWithCustomKeys() {
        let keyName = UUID().uuidString
        
        // Seed initial value
        let startingURL = "https://myDomain.com"
        UserDefaults.standard.set(startingURL, forKey: keyName)

        // Create new API with caching and the correct key name
        let api = API(
            enableURLCachingBehavior: true,
            urlOverrideKey: keyName
        )
        XCTAssertEqual(api.baseURL, startingURL)
        
        // Change url and monitor results
        let changedURL = "https://mySubdomain.myDomain.com"
        let didChange = api.set(url: changedURL)
        XCTAssertTrue(didChange)
        let storedValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(changedURL, storedValue)
        
        // Create a new API with caching and a custom URL
        let baseURLOverride = "https://otherSubdomain.myDomain.com"
        let newAPI = API(
            baseURL: baseURLOverride,
            enableURLCachingBehavior: true,
            urlOverrideKey: keyName
        )
        XCTAssertEqual(newAPI.baseURL, baseURLOverride)
        let newStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(baseURLOverride, newStoredValue)
        
        // Update the url to the same as init
        let didChangeOnUpdateToSame = newAPI.set(url: baseURLOverride)
        XCTAssertFalse(didChangeOnUpdateToSame)
        
        // Update the url and monitor continued caching
        let finalURL = "https://www.myOtherDomain.com"
        let didChangeOnUpdateToNew = newAPI.set(url: finalURL)
        XCTAssertTrue(didChangeOnUpdateToNew)
        let newerStoredValue = UserDefaults.standard.string(forKey: keyName)
        XCTAssertEqual(finalURL, newerStoredValue)
        
        // Create another api using the same key
        let newerAPI = API(config: TimeConfig(), enableURLCachingBehavior: true, urlOverrideKey: keyName)
        XCTAssertEqual(newerAPI.baseURL, finalURL)
    }
}
