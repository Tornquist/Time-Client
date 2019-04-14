//
//  Test_API_Accounts.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 1/12/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_API_Accounts: XCTestCase {
    
    static var accountID: Int? = nil
    
    override func setUp() {
        var succeeded = false
        let getTokenExpectation = self.expectation(description: "getToken")
        API.shared.getToken(withEmail: "test@test.com", andPassword: "defaultPassword") { (token, error) in
            XCTAssertNotNil(token)
            succeeded = token != nil
            getTokenExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        guard succeeded else {
            XCTFail("Token not found.")
            return
        }
    }
    
    override func tearDown() { }

    func test_createAccount() {
        let expectation = self.expectation(description: "createAccount")
        API.shared.createAccount() { (account, error) in
            XCTAssertNotNil(account)
            XCTAssertNil(error)
                
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_getAccounts() {
        let expectation = self.expectation(description: "getAccounts")
        API.shared.getAccounts() { (accounts, error) in
            XCTAssertNotNil(accounts)
            XCTAssertNil(error)
            
            if accounts != nil && accounts!.count > 0 {
                Test_API_Accounts.accountID = accounts![0].id
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_getSingleAccounts() {
        guard let accountID = Test_API_Accounts.accountID else {
            XCTFail("Dependent on accountID. Unable to perform test")
            return
        }
        
        let expectation = self.expectation(description: "getAccount")
        API.shared.getAccount(withID: accountID) { (account, error) in
            XCTAssertNotNil(account)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
