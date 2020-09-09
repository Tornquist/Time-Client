//
//  Test_API_Importer.swift
//  Shared
//
//  Created by Nathan Tornquist on 11/26/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_API_Importer: XCTestCase {
    static let config = TimeConfig()
    static var api: API!
    static var email = "\(UUID().uuidString)@time.com"
    static var password = "defaultPassword"

    static var importID: Int? = nil
    
    var api: API! { return Test_API_Importer.api }
    
    var email: String { return Test_API_Importer.email }
    var password: String { return Test_API_Importer.password }
    
    var importID: Int? { return Test_API_Importer.importID }

    override class func setUp() {
        self.api = API(config: self.config)
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
    
    func test_01_checkExistingImportRequests() {
        let importExpectation = self.expectation(description: "importer")
        self.api.getImportRequests { (requests, error) in
            XCTAssertNotNil(requests)
            XCTAssertNil(error)
            
            XCTAssertEqual(requests?.count, 0)
            importExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_02_createImportRequest() {
        self.continueAfterFailure = false
        
        // Setup
        let inputFileName = "import-example.csv"
        let fileParts = inputFileName.split(separator: ".").map({ String($0) })
        let bundle = Bundle(for: type(of: self))
        let fileURL = bundle.url(forResource: fileParts[0], withExtension: fileParts[1])!
        let importer = FileImporter(fileURL: fileURL, separator: ",")
        XCTAssertNoThrow(try importer.loadData())
        importer.categoryColumns = ["category", "project", "task", "subtask"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        XCTAssertNoThrow(try importer.setDateTimeParseRules(
            startUnixColumn: "unix_start",
            endUnixColumn: "unix_end",
            timezoneAbbreviation: "CST",
            testFormat: "MMM d, y @ h:mm a zzz"
        ))
        XCTAssertNoThrow(try importer.parseAll())
        
        // Network
        let importExpectation = self.expectation(description: "importer")
        self.api.importData(from: importer) { (request, error) in
            XCTAssertNotNil(request)
            XCTAssertNil(error)
            
            Test_API_Importer.importID = request?.id
            XCTAssertEqual(request?.categories.imported, 0)
            XCTAssertEqual(request?.categories.expected, 9)
            XCTAssertEqual(request?.entries.imported, 0)
            XCTAssertEqual(request?.entries.expected, 0 + 138)
            XCTAssertEqual(request?.complete, false)
            XCTAssertEqual(request?.success, false)
            
            importExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_03_check_specific_request() {
        guard self.importID != nil else {
            XCTFail()
            return
        }
        
        let importExpectation = self.expectation(description: "importer")
        self.api.getImportRequest(withID: self.importID!) { (request, error) in
            XCTAssertNotNil(request)
            XCTAssertNil(error)
            
            XCTAssertEqual(request?.id, self.importID)
            importExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
