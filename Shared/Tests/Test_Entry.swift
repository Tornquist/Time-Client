//
//  Test_Entry.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/26/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_Entry: XCTestCase {
    
    func test_decodable() {
        let startString = "2019-02-25T03:09:53.394Z"
        let endString = "2019-02-27T02:08:53.394Z"
        let entryDictionary: [String: Any] = [
            "id": 15,
            "type": "range",
            "category_id": 16,
            "started_at": startString,
            "ended_at": endString
        ]
        guard let entryData = try? JSONSerialization.data(
            withJSONObject: entryDictionary,
            options: .prettyPrinted
            ) else {
            XCTFail("EntryData cannot be nil")
               return
        }
        
        guard let entry = try? JSONDecoder().decode(Entry.self, from: entryData) else {
            XCTFail("Entry cannot be nil")
            return
        }
        
        XCTAssertEqual(entry.id, 15)
        XCTAssertEqual(entry.type, EntryType.range)
        XCTAssertEqual(entry.categoryID, 16)
        XCTAssertEqual(
            entry.startedAt.timeIntervalSinceReferenceDate,
            DateHelper.dateFrom(isoString: startString)?.timeIntervalSinceReferenceDate ?? -200,
            accuracy: 1.0
        )
        XCTAssertEqual(
            entry.endedAt?.timeIntervalSinceReferenceDate ?? -100,
            DateHelper.dateFrom(isoString: endString)?.timeIntervalSinceReferenceDate ?? -200,
            accuracy: 1.0
        )
    }
    
    func test_decodableError() {
        let entryDictionary: [String: Any] = [
            "id": 15,
            "type": "event",
            "category_id": 16,
            "started_at": "March 3rd, 2019 12:01pm"
        ]
        guard let entryData = try? JSONSerialization.data(
            withJSONObject: entryDictionary,
            options: .prettyPrinted
            ) else {
            XCTFail("Entry data could not be serialized")
            return
        }
        
        do {
            _ = try JSONDecoder().decode(Entry.self, from: entryData)
            XCTFail("Expected entry to throw")
        } catch {
            XCTAssertEqual(error as? TimeError, TimeError.unableToDecodeResponse())
        }
    }
    
    func test_encodable() {
        let id = 16
        let type = EntryType.event
        let categoryID = 17
        let startedAt = Date()
        
        let entry = Entry(id: id, type: type, categoryID: categoryID, startedAt: startedAt, endedAt: nil)
        
        guard let encodedEntry = try? JSONEncoder().encode(entry) else {
            XCTFail("Entry could not be encoded")
            return
        }
        
        guard let decodedEntry = try? JSONDecoder().decode(Entry.self, from: encodedEntry) else {
            XCTFail("Entry could not be decoded")
            return
        }
        
        XCTAssertEqual(entry.id, decodedEntry.id)
        XCTAssertEqual(entry.type, decodedEntry.type)
        XCTAssertEqual(entry.categoryID, decodedEntry.categoryID)
        XCTAssertEqual(
            entry.startedAt.timeIntervalSinceReferenceDate,
            decodedEntry.startedAt.timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )
    }
}
