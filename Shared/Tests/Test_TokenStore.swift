//
//  Test_TokenStore.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/20/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import Time

class Test_TokenStore: XCTestCase {
    
    func test_0_clearAnyExistingToken() {
        // Note: This allows individual tests to be re-run without a global clear at start
        _ = TokenStore.deleteToken(withTag: "test-token")
    }

    func test_1_startsWithNoToken() {
        let token = TokenStore.getToken(withTag: "test-token")
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
        
        let result = TokenStore.storeToken(token, withTag: "test-token")
        XCTAssertTrue(result)
    }
    
    func test_3_allowsRetrievalOfAToken() {
        self.continueAfterFailure = false
        
        let token = TokenStore.getToken(withTag: "test-token")
        XCTAssertNotNil(token)
        
        XCTAssertEqual(token!.userID, 1234)
        XCTAssertEqual(token!.creation.timeIntervalSinceReferenceDate, 0, accuracy: 0.01)
        XCTAssertEqual(token!.expiration.timeIntervalSinceReferenceDate, 10000, accuracy: 0.01)
        XCTAssertEqual(token!.token, "myToken")
        XCTAssertEqual(token!.refresh, "myRefreshToken")
    }
    
    func test_4_allowsANewTokenToBeStored() {
        let token = Token(
            userID: 1235,
            creation: Date(timeIntervalSinceReferenceDate: 10),
            expiration: Date(timeIntervalSinceReferenceDate: 20000),
            token: "myNewToken",
            refresh: "myNewRefreshToken"
        )
        
        let result = TokenStore.storeToken(token, withTag: "test-token")
        XCTAssertTrue(result)
    }
    
    func test_5_allowsRetrievalOfTheMostRecentToken() {
        self.continueAfterFailure = false
        
        let token = TokenStore.getToken(withTag: "test-token")
        XCTAssertNotNil(token)
        
        XCTAssertEqual(token!.userID, 1235)
        XCTAssertEqual(token!.creation.timeIntervalSinceReferenceDate, 10, accuracy: 0.01)
        XCTAssertEqual(token!.expiration.timeIntervalSinceReferenceDate, 20000, accuracy: 0.01)
        XCTAssertEqual(token!.token, "myNewToken")
        XCTAssertEqual(token!.refresh, "myNewRefreshToken")
    }
    
    func test_6_allowsDeletion() {
        let result = TokenStore.deleteToken(withTag: "test-token")
        XCTAssertTrue(result)
    }
    
    func test_7_returnsNoTokenAfterDeletion() {
        let token = TokenStore.getToken(withTag: "test-token")
        XCTAssertNil(token)
    }
}
