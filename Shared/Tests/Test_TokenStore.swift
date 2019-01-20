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
    override func setUp() { }
    
    override func tearDown() { }
    
    func test_getToken() {
        let token = TokenStore.getToken()
        XCTAssertNil(token)
    }
    
    func test_storeToken() {
        let token = Token(
            userID: 1234,
            creation: Date(),
            expiration: Date(),
            token: "myToken",
            refresh: "myRefreshToken"
        )
        
        let result = TokenStore.storeToken(token)
        print(result)
    }
}
