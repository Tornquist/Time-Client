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
    
    static let archive: Archive = Archive(config: TimeConfig())
    var archive: Archive { return Test_Archive.archive }
    
    func test_00_setup() {
        _ = self.archive.removeAllData()
    }
    
    func test_01_startsWithNoData() {
        let entries: [Entry]? = self.archive.retrieveData()
        let categories: [TimeSDK.Category]? = self.archive.retrieveData()
        let accountIDs: [Int]? = self.archive.retrieveData()
        
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
        let success = self.archive.record(entries)
        XCTAssertTrue(success)
        
        // Retrieve for various types
        let freshEntries: [Entry]? = self.archive.retrieveData()
        let categories: [TimeSDK.Category]? = self.archive.retrieveData()
        let accountIDs: [Int]? = self.archive.retrieveData()
        
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
        let success = self.archive.record(entries)
        XCTAssertTrue(success)
        
        // Retrieve for various types
        let freshEntries: [Entry]? = self.archive.retrieveData()
        let categories: [TimeSDK.Category]? = self.archive.retrieveData()
        let accountIDs: [Int]? = self.archive.retrieveData()
        
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
        let success = self.archive.record(accountIDs)
        XCTAssertTrue(success)
        
        // Verify
        let startingEntries: [Entry]? = self.archive.retrieveData()
        let startingAccountIDs: [Int]? = self.archive.retrieveData()
        XCTAssertNotNil(startingEntries)
        XCTAssertNotNil(startingAccountIDs)
        
        // Purge
        let removed = self.archive.removeData(for: .entries)
        XCTAssertTrue(removed)
        
        // Verify
        let endingEntries: [Entry]? = self.archive.retrieveData()
        let endingAccountIDs: [Int]? = self.archive.retrieveData()
        XCTAssertNil(endingEntries)
        XCTAssertNotNil(endingAccountIDs)
    }
    
    func test_05_ignoresOtherTypes() {
        let randomData = [true, false, true]
        
        let success = self.archive.record(randomData)
        XCTAssertFalse(success)
    }
    
    func test_06_canRemoveAll() {
        let removedAll = self.archive.removeAllData()
        XCTAssertTrue(removedAll)
    }
}
