//
//  Test_Split.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/16/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_Split: XCTestCase {
    
    // MARK: - Boilerplate
    
    func test_directInit() {
        let split = Split(
            year: 2020,
            month: 1,
            day: 2,
            duration: 10,
            categoryID: 3,
            entryID: 4,
            open: true
        )
        
        XCTAssertEqual(split.year, 2020)
        XCTAssertEqual(split.month, 1)
        XCTAssertEqual(split.day, 2)
        XCTAssertEqual(split.duration, 10)
        XCTAssertEqual(split.categoryID, 3)
        XCTAssertEqual(split.entryID, 4)
        XCTAssertEqual(split.open, true)
    }
    
    func test_initFromEntry() {
        let entry = Entry(
            id: 4,
            type: .range,
            categoryID: 3,
            startedAt: Date(),
            endedAt: Date()
        )
        
        let split = Split(
            for: entry,
            year: 2020,
            month: 1,
            day: 2,
            duration: 10,
            open: false
        )
        
        XCTAssertEqual(split.year, 2020)
        XCTAssertEqual(split.month, 1)
        XCTAssertEqual(split.day, 2)
        XCTAssertEqual(split.duration, 10)
        XCTAssertEqual(split.categoryID, 3)
        XCTAssertEqual(split.entryID, 4)
        XCTAssertEqual(split.open, false)
    }
    
    func test_initFromExisting() {
        let split = Split(
            year: 2020,
            month: 1,
            day: 2,
            duration: 10,
            categoryID: 3,
            entryID: 4,
            open: true
        )
        
        let newSplit = Split(
            from: split,
            duration: 20,
            categoryID: 30,
            entryID: 40,
            open: false
        )
        
        XCTAssertEqual(newSplit.year, 2020)
        XCTAssertEqual(newSplit.month, 1)
        XCTAssertEqual(newSplit.day, 2)
        XCTAssertEqual(newSplit.duration, 20)
        XCTAssertEqual(newSplit.categoryID, 30)
        XCTAssertEqual(newSplit.entryID, 40)
        XCTAssertEqual(newSplit.open, false)
    }
    
    func test_initFromExistingWithoutChanges() {
        let split = Split(
            year: 2020,
            month: 1,
            day: 2,
            duration: 10,
            categoryID: 3,
            entryID: 4,
            open: true
        )
        
        let newSplit = Split(from: split)
        
        XCTAssertEqual(newSplit.year, 2020)
        XCTAssertEqual(newSplit.month, 1)
        XCTAssertEqual(newSplit.day, 2)
        XCTAssertEqual(newSplit.duration, 10)
        XCTAssertEqual(newSplit.categoryID, 3)
        XCTAssertEqual(newSplit.entryID, 4)
        XCTAssertEqual(newSplit.open, true)
    }
    
    // MARK: - True generation
    
    func test_generateForSingleDayOnly() {
        let timeZoneString = "EST"
        let timeZone = DateHelper.getSafeTimezone(identifier: timeZoneString)
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = timeZone
        
        guard
            let start = formatter.date(from: "2020-01-02T11:30:16-05:00"),
            let end = formatter.date(from: "2020-01-02T13:45:18-05:00") else {
            XCTFail("Could not generate seed dates")
            return
        }
                
        let entry = Entry(
            id: 4,
            type: .range,
            categoryID: 3,
            startedAt: start,
            startedAtTimezone: timeZoneString,
            endedAt: end,
            endedAtTimezone: timeZoneString
        )
        
        let splits = Split.identify(for: entry)

        guard splits.count == 1 else {
            XCTFail("Unexpected number of splits generated")
            return
        }
        
        let expectedHourDiff: TimeInterval = 2 * 60 * 60
        let expectedMinuteDiff: TimeInterval = 15 * 60
        let expectedSecondDiff: TimeInterval = 2
        let expectedDuration: TimeInterval = expectedHourDiff + expectedMinuteDiff + expectedSecondDiff
        
        let split = splits[0]
        XCTAssertEqual(split.year, 2020)
        XCTAssertEqual(split.month, 1)
        XCTAssertEqual(split.day, 2)
        XCTAssertEqual(split.duration, expectedDuration)
        XCTAssertEqual(split.categoryID, 3)
        XCTAssertEqual(split.entryID, 4)
        XCTAssertEqual(split.open, false)
    }
    
    func test_generateOpenToday() {
        let timeZoneString = "PST"
        let timeZone = DateHelper.getSafeTimezone(identifier: timeZoneString)
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = timeZone
        
        // Note: This test will not work if run within 1:02:16 of the start of the day PST
        
        let hourDiff = 1
        let minuteDiff = 2
        let secondDiff = 16
        
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.setValue((components.hour ?? 0) - hourDiff, for: .hour)
        components.setValue((components.minute ?? 0) - minuteDiff, for: .minute)
        components.setValue((components.second ?? 0) - secondDiff, for: .second)
        components.timeZone = timeZone

        guard
            let startTime = calendar.date(from: components) else {
            XCTFail("Could not generate seed date")
            return
        }
        
        let targetDuration: TimeInterval = TimeInterval(hourDiff * 60 * 60 + minuteDiff * 60 + secondDiff)
        
        let entry = Entry(
            id: 4,
            type: .range,
            categoryID: 3,
            startedAt: startTime,
            startedAtTimezone: timeZoneString,
            endedAt: nil,
            endedAtTimezone: nil
        )
        
        let splits = Split.identify(for: entry)

        guard splits.count == 1 else {
            XCTFail("Unexpected number of splits generated")
            return
        }
        
        let split = splits[0]
        XCTAssertEqual(split.year, components.year ?? 0)
        XCTAssertEqual(split.month, components.month ?? 0)
        XCTAssertEqual(split.day, components.day ?? 0)
        XCTAssertEqual(split.duration, targetDuration, accuracy: 1.0) // within 1s
        XCTAssertEqual(split.categoryID, 3)
        XCTAssertEqual(split.entryID, 4)
        XCTAssertEqual(split.open, true)
    }
    
    func test_generateAcrossDays() {
        // Display timezone does not impact results
        let displayTimeZoneString = "CST"
        let dataTimeZoneString = "EST"
        
        let timeZone = DateHelper.getSafeTimezone(identifier: displayTimeZoneString)
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = timeZone
        
        guard
            let start = formatter.date(from: "2020-01-02T11:30:16-05:00"),
            let end = formatter.date(from: "2020-01-03T13:45:18-05:00") else {
            XCTFail("Could not generate seed dates")
            return
        }
                
        let entry = Entry(
            id: 4,
            type: .range,
            categoryID: 3,
            startedAt: start,
            startedAtTimezone: dataTimeZoneString,
            endedAt: end,
            endedAtTimezone: dataTimeZoneString
        )
        
        let splits = Split.identify(for: entry)
        
        guard splits.count == 2 else {
            XCTFail("Unexpected number of splits generated")
            return
        }
        
        /* In EST time (as set in event) */
        let expectedStartSecondDiff: TimeInterval = /* 16 -> 60 */ 44
        let expectedStartMinuteDiff: TimeInterval = /* 31 (with seconds) to 60 */ 29 * 60
        let expectedStartHourDiff: TimeInterval = /* 12 (with minutes) to 24 */ 12 * 60 * 60
        let expectedStartDuration: TimeInterval = expectedStartSecondDiff + expectedStartMinuteDiff + expectedStartHourDiff
        
        let startSplit = splits[0]
        XCTAssertEqual(startSplit.year, 2020)
        XCTAssertEqual(startSplit.month, 1)
        XCTAssertEqual(startSplit.day, 2)
        XCTAssertEqual(startSplit.duration, expectedStartDuration)
        XCTAssertEqual(startSplit.categoryID, 3)
        XCTAssertEqual(startSplit.entryID, 4)
        XCTAssertEqual(startSplit.open, false)
        
        /* In EST time (as set in event) */
        let expectedEndSecondDiff: TimeInterval = /* 0 -> 18 */ 18
        let expectedEndMinuteDiff: TimeInterval = /* 0 -> 45 */ 45 * 60
        let expectedEndHourDiff: TimeInterval = /* 0 -> 13 */ 13 * 60 * 60
        let expectedEndDuration: TimeInterval = expectedEndSecondDiff + expectedEndMinuteDiff + expectedEndHourDiff
        
        let endSplit = splits[1]
        XCTAssertEqual(endSplit.year, 2020)
        XCTAssertEqual(endSplit.month, 1)
        XCTAssertEqual(endSplit.day, 3)
        XCTAssertEqual(endSplit.duration, expectedEndDuration)
        XCTAssertEqual(endSplit.categoryID, 3)
        XCTAssertEqual(endSplit.entryID, 4)
        XCTAssertEqual(endSplit.open, false)
    }
    
    func test_generateAcrossTwoDays() {
        // Display timezone does not impact results
        let displayTimeZoneString = "CST"
        let dataTimeZoneString = "EST"
        
        let timeZone = DateHelper.getSafeTimezone(identifier: displayTimeZoneString)
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = timeZone
        
        guard
            let start = formatter.date(from: "2020-01-02T11:30:16-05:00"),
            let end = formatter.date(from: "2020-01-04T13:45:18-05:00") else {
            XCTFail("Could not generate seed dates")
            return
        }
                
        let entry = Entry(
            id: 4,
            type: .range,
            categoryID: 3,
            startedAt: start,
            startedAtTimezone: dataTimeZoneString,
            endedAt: end,
            endedAtTimezone: dataTimeZoneString
        )
        
        let splits = Split.identify(for: entry)
        
        guard splits.count == 3 else {
            XCTFail("Unexpected number of splits generated")
            return
        }
        
        /* In EST time (as set in event) */
        let expectedStartSecondDiff: TimeInterval = /* 16 -> 60 */ 44
        let expectedStartMinuteDiff: TimeInterval = /* 31 (with seconds) to 60 */ 29 * 60
        let expectedStartHourDiff: TimeInterval = /* 12 (with minutes) to 24 */ 12 * 60 * 60
        let expectedStartDuration: TimeInterval = expectedStartSecondDiff + expectedStartMinuteDiff + expectedStartHourDiff
        
        let startSplit = splits[0]
        XCTAssertEqual(startSplit.year, 2020)
        XCTAssertEqual(startSplit.month, 1)
        XCTAssertEqual(startSplit.day, 2)
        XCTAssertEqual(startSplit.duration, expectedStartDuration)
        XCTAssertEqual(startSplit.categoryID, 3)
        XCTAssertEqual(startSplit.entryID, 4)
        XCTAssertEqual(startSplit.open, false)
        
        /* In EST time (as set in event) */
        let expectedMiddleDuration: TimeInterval = 24 * 60 * 60
        
        let middleSplit = splits[1]
        XCTAssertEqual(middleSplit.year, 2020)
        XCTAssertEqual(middleSplit.month, 1)
        XCTAssertEqual(middleSplit.day, 3)
        XCTAssertEqual(middleSplit.duration, expectedMiddleDuration)
        XCTAssertEqual(middleSplit.categoryID, 3)
        XCTAssertEqual(middleSplit.entryID, 4)
        XCTAssertEqual(middleSplit.open, false)
        
        /* In EST time (as set in event) */
        let expectedEndSecondDiff: TimeInterval = /* 0 -> 18 */ 18
        let expectedEndMinuteDiff: TimeInterval = /* 0 -> 45 */ 45 * 60
        let expectedEndHourDiff: TimeInterval = /* 0 -> 13 */ 13 * 60 * 60
        let expectedEndDuration: TimeInterval = expectedEndSecondDiff + expectedEndMinuteDiff + expectedEndHourDiff
        
        let endSplit = splits[2]
        XCTAssertEqual(endSplit.year, 2020)
        XCTAssertEqual(endSplit.month, 1)
        XCTAssertEqual(endSplit.day, 4)
        XCTAssertEqual(endSplit.duration, expectedEndDuration)
        XCTAssertEqual(endSplit.categoryID, 3)
        XCTAssertEqual(endSplit.entryID, 4)
        XCTAssertEqual(endSplit.open, false)
    }
    
    func test_generateOpenAcrossDays() {
        let timeZoneString = "PST"
        let timeZone = DateHelper.getSafeTimezone(identifier: timeZoneString)
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = timeZone
        
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        
        let secondDayHoursQuantity: Int = (components.hour ?? 0) * 60 * 60
        let secondDayMinuteQuantity: Int = (components.minute ?? 0) * 60
        let secondDaySecondQuantity: Int = (components.second ?? 0)
        let secondDayDuration = TimeInterval(secondDayHoursQuantity + secondDayMinuteQuantity + secondDaySecondQuantity)
        components.setValue(18, for: .hour)
        components.setValue(31, for: .minute)
        components.setValue(25, for: .second)
        components.timeZone = timeZone

        let dayShift = DateComponents(day: -1)
        
        guard
            let startBase = calendar.date(from: components),
            let startTime = calendar.date(byAdding: dayShift, to: startBase),
            let startDay = calendar.dateComponents([.day], from: startTime).day
            else {
            XCTFail("Could not generate seed date")
            return
        }
        
        let entry = Entry(
            id: 4,
            type: .range,
            categoryID: 3,
            startedAt: startTime,
            startedAtTimezone: timeZoneString,
            endedAt: nil,
            endedAtTimezone: nil
        )
        
        let splits = Split.identify(for: entry)

        guard splits.count == 2 else {
            XCTFail("Unexpected number of splits generated")
            return
        }
        
        let firstDayDuration = TimeInterval((60 - 25) + (60 - 31 - 1) * 60 + (24 - 18 - 1) * 60 * 60)
        let firstDay = splits[0]
        XCTAssertEqual(firstDay.year, components.year ?? 0)
        XCTAssertEqual(firstDay.month, components.month ?? 0)
        XCTAssertEqual(firstDay.day, startDay)
        XCTAssertEqual(firstDay.duration, firstDayDuration, accuracy: 1.0) // within 1s
        XCTAssertEqual(firstDay.categoryID, 3)
        XCTAssertEqual(firstDay.entryID, 4)
        XCTAssertEqual(firstDay.open, false)
        
        let secondDay = splits[1]
        XCTAssertEqual(secondDay.year, components.year ?? 0)
        XCTAssertEqual(secondDay.month, components.month ?? 0)
        XCTAssertEqual(secondDay.day, components.day ?? 0)
        XCTAssertEqual(secondDay.duration, secondDayDuration, accuracy: 1.0) // within 1s
        XCTAssertEqual(secondDay.categoryID, 3)
        XCTAssertEqual(secondDay.entryID, 4)
        XCTAssertEqual(secondDay.open, true)
    }
}
