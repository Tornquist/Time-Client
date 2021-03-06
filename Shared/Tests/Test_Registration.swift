//
//  Test_Registration.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_Registration: XCTestCase {

    static let config = TimeConfig(tokenIdentifier: "test-registration-tests")
    static var api: API!
    static var time: Time!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"
    
    var tokenTag: String { return Test_Registration.config.tokenIdentifier! }
    var api: API! { return Test_Registration.api }
    var time: Time! { return Test_Registration.time }
    
    var email: String { return Test_Registration.email }
    var password: String { return Test_Registration.password }
    
    override class func setUp() {
        self.api = API(config: self.config)
        self.time = Time(config: self.config, withAPI: self.api)
    }
    
    func test_1_registerANewAccount() {
        let expectation = self.expectation(description: "register")
        self.time.register(email: self.email, password: self.password) { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNotNil(self.api.token)
    }
    
    func test_2_rejectReRegisterANewAccount() {
        let expectation = self.expectation(description: "register")
        self.time.register(email: self.email, password: self.password) { (error) in
            XCTAssertEqual(error as? TimeError, TimeError.httpFailure("409"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
