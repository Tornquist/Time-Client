//
//  Test_Token.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/19/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import Time

class Test_Token: XCTestCase {
    override func setUp() { }
    
    override func tearDown() { }
    
    func test_decodable() {
        self.continueAfterFailure = false
        
        // Default date parsing is in seconds. API returns MS.
        // creation: Saturday, January 19, 2019 1:00:35.987 PM GMT-06:00
        // expiration: Saturday, January 19, 2019 5:00:35.987 PM GMT-06:00
        let tokenDictionary: [String: Any] = [
            "user_id": 1449,
            "creation": 1547924435987,
            "expiration": 1547938835987,
            "token": "6coYVjJb168677c74131c76yC7yDabbIB9QKbk",
            "refresh": "e4uL1c2tNlEkAlab168677c74131c76Dg2yznuTZ24n3xj6Y"
        ]
        let tokenData = try? JSONSerialization.data(
            withJSONObject: tokenDictionary,
            options: .prettyPrinted
        )
        XCTAssertNotNil(tokenData)

        let token = try? JSONDecoder().decode(Token.self, from: tokenData!)
        XCTAssertNotNil(token)
        
        XCTAssertEqual(token!.userID, tokenDictionary["user_id"] as! Int)
        print(token!.creation)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS Z"
        // Generate dates in CST as example. Will compare in GMT
        let expectedCreationTime = formatter.date(from: "2019/01/19 13:00:35.987 -0600")!
        let expectedRefreshTime = formatter.date(from: "2019/01/19 17:00:35.987 -0600")!
        XCTAssertEqual(token!.creation.timeIntervalSinceReferenceDate, expectedCreationTime.timeIntervalSinceReferenceDate, accuracy: 0.001)
        XCTAssertEqual(token!.expiration.timeIntervalSinceReferenceDate, expectedRefreshTime.timeIntervalSinceReferenceDate, accuracy: 0.001)

        XCTAssertEqual(token!.token, tokenDictionary["token"] as! String)
        XCTAssertEqual(token!.refresh, tokenDictionary["refresh"] as! String)
    }
    
    func test_encodable() {
        self.continueAfterFailure = false
        
        let userID = 1234
        let creation = Date()
        let expiration = Date()
        let tokenKey = "6coYVjJb168677c74131c76yC7yDabbIB9QKbk"
        let refreshKey = "e4uL1c2tNlEkAlab168677c74131c76Dg2yznuTZ24n3xj6Y"
        
        let token = Token(userID: userID, creation: creation, expiration: expiration, token: tokenKey, refresh: refreshKey)
        
        let encodedToken = try? JSONEncoder().encode(token)
        XCTAssertNotNil(encodedToken)
        let decodedToken = try? JSONDecoder().decode(Token.self, from: encodedToken!)
        XCTAssertNotNil(decodedToken)
        
        XCTAssertEqual(token.userID, decodedToken!.userID)
        XCTAssertEqual(token.creation.timeIntervalSinceReferenceDate, decodedToken!.creation.timeIntervalSinceReferenceDate, accuracy: 0.001)
        XCTAssertEqual(token.expiration.timeIntervalSinceReferenceDate, decodedToken!.expiration.timeIntervalSinceReferenceDate, accuracy: 0.001)
        XCTAssertEqual(token.token, decodedToken!.token)
        XCTAssertEqual(token.refresh, decodedToken!.refresh)
    }
}
