//
//  Test_Archive.swift
//  Shared
//
//  Created by Nathan Tornquist on 9/19/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import TimeSDK

class Test_Archive: XCTestCase {
    func test_00_setup() {
        _ = Archive.removeAllData()
    }
    
    func test_01_startsWithNoData() {
        let entries: [Entry]? = Archive.retrieveData()
        let categories: [TimeSDK.Category]? = Archive.retrieveData()
        let accountIDs: [Int]? = Archive.retrieveData()
        
        XCTAssertNil(entries)
        XCTAssertNil(categories)
        XCTAssertNil(accountIDs)
    }
    
    func test_02_storingDataMapsTypes() {
        let entries: [Entry] = [Entry(
            id: 15,
            type: .event,
            categoryID: 3,
            startedAt: Date(),
            endedAt: nil
        )]
        
        // Store data
        let success = Archive.record(entries)
        XCTAssertTrue(success)
        
        // Retrieve for various types
        let freshEntries: [Entry]? = Archive.retrieveData()
        let categories: [TimeSDK.Category]? = Archive.retrieveData()
        let accountIDs: [Int]? = Archive.retrieveData()
        
        XCTAssertNotNil(freshEntries)
        XCTAssertNil(categories)
        XCTAssertNil(accountIDs)
        
        XCTAssertEqual(freshEntries?.count, 1)
        
        guard let entry = freshEntries?.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(entries[0].id, entry.id)
        XCTAssertEqual(entries[0].type, entry.type)
        XCTAssertEqual(entries[0].categoryID, entry.categoryID)
        XCTAssertEqual(entries[0].startedAt.timeIntervalSinceReferenceDate, entry.startedAt.timeIntervalSinceReferenceDate, accuracy: 0.01)
        XCTAssertEqual(entries[0].endedAt, entry.endedAt)
    }
    
    func test_03_storingNewDataOverrides() {
        let entries: [Entry] = [
            Entry(
                id: 16,
                type: .event,
                categoryID: 4,
                startedAt: Date(),
                endedAt: nil
            ),
            Entry(
                id: 17,
                type: .event,
                categoryID: 5,
                startedAt: Date(),
                endedAt: nil
            )
        ]
        
        // Store data
        let success = Archive.record(entries)
        XCTAssertTrue(success)
        
        // Retrieve for various types
        let freshEntries: [Entry]? = Archive.retrieveData()
        let categories: [TimeSDK.Category]? = Archive.retrieveData()
        let accountIDs: [Int]? = Archive.retrieveData()
        
        XCTAssertNotNil(freshEntries)
        XCTAssertNil(categories)
        XCTAssertNil(accountIDs)
        
        XCTAssertEqual(freshEntries?.count, 2)
        
        let freshEntryIDs = (freshEntries ?? []).map({ $0.id })
        XCTAssertFalse(freshEntryIDs.contains(15)) // Test 2
        XCTAssertTrue(freshEntryIDs.contains(16))
        XCTAssertTrue(freshEntryIDs.contains(17))
    }
    
    func test_04_dataCanBeExplicitlyRemoved() {
        // Set Data
        // Entries depend on test 3
        let accountIDs = [1, 2, 3]
        let success = Archive.record(accountIDs)
        XCTAssertTrue(success)
        
        // Verify
        let startingEntries: [Entry]? = Archive.retrieveData()
        let startingAccountIDs: [Int]? = Archive.retrieveData()
        XCTAssertNotNil(startingEntries)
        XCTAssertNotNil(startingAccountIDs)
        
        // Purge
        let removed = Archive.removeData(for: .entries)
        XCTAssertTrue(removed)
        
        // Verify
        let endingEntries: [Entry]? = Archive.retrieveData()
        let endingAccountIDs: [Int]? = Archive.retrieveData()
        XCTAssertNil(endingEntries)
        XCTAssertNotNil(endingAccountIDs)
    }
    
    func test_05_ignoresOtherTypes() {
        let randomData = [true, false, true]
        
        let success = Archive.record(randomData)
        XCTAssertFalse(success)
    }
    
    func test_06_canRemoveAll() {
        let removedAll = Archive.removeAllData()
        XCTAssertTrue(removedAll)
    }
}
