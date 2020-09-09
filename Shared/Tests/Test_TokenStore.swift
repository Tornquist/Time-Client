//
//  Test_TokenStore.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/20/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import TimeSDK

class Test_TokenStore: XCTestCase {
    
    static let config = TimeConfig(tokenIdentifier: "test-token")
    static let tokenStore = TokenStore(config: config)
    
    var tokenStore: TokenStore { return Test_TokenStore.tokenStore }
    
    func test_0_clearAnyExistingToken() {
        // Note: This allows individual tests to be re-run without a global clear at start
        _ = self.tokenStore.deleteToken()
    }

    func test_1_startsWithNoToken() {
        let token = self.tokenStore.getToken()
        XCTAssertNil(token)
    }
    
    func test_2_allowsATokenToBeStored() {
        let token = Token(
            userID: 1234,
            creation: Date(timeIntervalSinceReferenceDate: 0),
            expiration: Date(timeIntervalSinceReferenceDate: 10000),
            token: "myToken",
            refresh: "myRefreshToken"
        )
        
        let result = self.tokenStore.storeToken(token)
        XCTAssertTrue(result)
    }
    
    func test_3_allowsRetrievalOfAToken() {
        guard let token = self.tokenStore.getToken() else {
            XCTFail("Token not found.")
            return
        }
        
        XCTAssertEqual(token.userID, 1234)
        XCTAssertEqual(token.creation.timeIntervalSinceReferenceDate, 0, accuracy: 0.01)
        XCTAssertEqual(token.expiration.timeIntervalSinceReferenceDate, 10000, accuracy: 0.01)
        XCTAssertEqual(token.token, "myToken")
        XCTAssertEqual(token.refresh, "myRefreshToken")
    }
    
    func test_4_allowsANewTokenToBeStored() {
        let token = Token(
            userID: 1235,
            creation: Date(timeIntervalSinceReferenceDate: 10),
            expiration: Date(timeIntervalSinceReferenceDate: 20000),
            token: "myNewToken",
            refresh: "myNewRefreshToken"
        )
        
        let result = self.tokenStore.storeToken(token)
        XCTAssertTrue(result)
    }
    
    func test_5_allowsRetrievalOfTheMostRecentToken() {
        guard let token = self.tokenStore.getToken() else {
            XCTFail("Token not found.")
            return
        }
        
        XCTAssertEqual(token.userID, 1235)
        XCTAssertEqual(token.creation.timeIntervalSinceReferenceDate, 10, accuracy: 0.01)
        XCTAssertEqual(token.expiration.timeIntervalSinceReferenceDate, 20000, accuracy: 0.01)
        XCTAssertEqual(token.token, "myNewToken")
        XCTAssertEqual(token.refresh, "myNewRefreshToken")
    }
    
    func test_6_allowsDeletion() {
        let result = self.tokenStore.deleteToken()
        XCTAssertTrue(result)
    }
    
    func test_7_returnsNoTokenAfterDeletion() {
        let token = self.tokenStore.getToken()
        XCTAssertNil(token)
    }
}
