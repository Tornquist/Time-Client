//
//  Test_API_Accounts.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/12/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import Time

class Test_API_Accounts: XCTestCase {
    
    override func setUp() { }
    
    override func tearDown() { }

    func test_getToken_createAccount() {
        let expectation = self.expectation(description: "createAccount")
        
        API.shared.getToken(withUsername: "test@test.com", andPassword: "defaultPassword") { (token, error) in

            XCTAssertNotNil(token)
            
            API.shared.createAccount() { (account, error) in
                XCTAssertNotNil(account)
                XCTAssertNil(error)
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_getToken_getAccounts() {
        let expectation = self.expectation(description: "getAccounts")
        
        API.shared.getToken(withUsername: "test@test.com", andPassword: "defaultPassword") { (token, error) in
            
            XCTAssertNotNil(token)
            
            API.shared.getAccounts() { (accounts, error) in
                XCTAssertNotNil(accounts)
                XCTAssertNil(error)
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
