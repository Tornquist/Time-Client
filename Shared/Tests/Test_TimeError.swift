//
//  Test_TimeError.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/16/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_TimeError: XCTestCase {
    
    func test_equalityValidatesMessageContents() {
        XCTAssertEqual(TimeError.unableToSendRequest("A"), TimeError.unableToSendRequest("A"))
        XCTAssertNotEqual(TimeError.unableToSendRequest("A"), TimeError.unableToSendRequest("B"))
        
        XCTAssertEqual(TimeError.requestFailed("A"), TimeError.requestFailed("A"))
        XCTAssertNotEqual(TimeError.requestFailed("A"), TimeError.requestFailed("B"))
        
        XCTAssertEqual(TimeError.httpFailure("A"), TimeError.httpFailure("A"))
        XCTAssertNotEqual(TimeError.httpFailure("A"), TimeError.httpFailure("B"))
        
        XCTAssertEqual(TimeError.authenticationFailure("A"), TimeError.authenticationFailure("A"))
        XCTAssertNotEqual(TimeError.authenticationFailure("A"), TimeError.authenticationFailure("B"))
    }
    
    func test_equalityPassesWhenNoMessageIsSupported() {
        XCTAssertEqual(TimeError.unableToDecodeResponse(), TimeError.unableToDecodeResponse())
        XCTAssertEqual(TimeError.tokenNotFound(), TimeError.tokenNotFound())
        XCTAssertEqual(TimeError.unableToRefreshToken(), TimeError.unableToRefreshToken())
    }
    
    func test_equalityValidatesType() {
        let a = TimeError.unableToSendRequest("")
        let b = TimeError.unableToDecodeResponse()
        let c = TimeError.requestFailed("")
        let d = TimeError.httpFailure("")
        let e = TimeError.authenticationFailure("")
        let f = TimeError.tokenNotFound()
        let g = TimeError.unableToRefreshToken()
        
        XCTAssertNotEqual(a, b)
        XCTAssertNotEqual(b, c)
        XCTAssertNotEqual(c, d)
        XCTAssertNotEqual(d, e)
        XCTAssertNotEqual(e, f)
        XCTAssertNotEqual(f, g)
        XCTAssertNotEqual(g, a)
    }
}
