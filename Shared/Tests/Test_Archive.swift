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
        Archive.removeAllData()
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
        Archive.record(entries)
        
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
        Archive.record(entries)
        
        // Retrieve for various types
        let freshEntries: [Entry]? = Archive.retrieveData()
        let categories: [TimeSDK.Category]? = Archive.retrieveData()
        let accountIDs: [Int]? = Archive.retrieveData()
        
        XCTAssertNotNil(freshEntries)
        XCTAssertNil(categories)
        XCTAssertNil(accountIDs)
        
        XCTAssertEqual(freshEntries?.count, 2)
    }
    
    func test_04_dataCanBeExplicitlyRemoved() {
        let startingEntries: [Entry]? = Archive.retrieveData()
        XCTAssertNotNil(startingEntries)
        
        Archive.removeData(for: .entries)
        
        let endingEntries: [Entry]? = Archive.retrieveData()
        XCTAssertNil(endingEntries)
    }
}
