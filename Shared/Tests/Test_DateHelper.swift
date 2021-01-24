//
//  Test_DateHelper.swift
//  Shared-Tests
//
//  Created by Nathan Tornquist on 2/25/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_DateHelper: XCTestCase {
    
    // MARK: - Iso In/Out
    
    func test_stringFromDateWithMilliseconds() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = DateComponents(
            year: 2018,
            month: 3,
            day: 12,
            hour: 8,
            minute: 32,
            second: 53,
            nanosecond: 342000000
        )
        
        let date = calendar.date(from: components)!
        let dateStringExplicit = DateHelper.isoStringFrom(date: date, includeMilliseconds: true)
        let dateStringDefault = DateHelper.isoStringFrom(date: date)
        
        XCTAssertEqual(dateStringExplicit, "2018-03-12T08:32:53.342Z")
        XCTAssertEqual(dateStringExplicit, dateStringDefault)
    }
    
    func test_stringFromDateWithoutMilliseconds() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = DateComponents(
            year: 2018,
            month: 3,
            day: 12,
            hour: 8,
            minute: 32,
            second: 53
        )
        
        let date = calendar.date(from: components)!
        let dateString = DateHelper.isoStringFrom(date: date, includeMilliseconds: false)
        
        XCTAssertEqual(dateString, "2018-03-12T08:32:53Z")
    }
    
    func test_dateFromStringWithMilliseconds() {
        let dateString = "2019-02-25T03:09:53.394Z"
        let date = DateHelper.dateFrom(isoString: dateString)
        
        XCTAssertNotNil(date)
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date!)
        XCTAssertEqual(dateComponents.year, 2019)
        XCTAssertEqual(dateComponents.month, 2)
        XCTAssertEqual(dateComponents.day, 25)
        XCTAssertEqual(dateComponents.hour, 3)
        XCTAssertEqual(dateComponents.minute, 9)
        XCTAssertEqual(dateComponents.second, 53)
        XCTAssertEqual(Double(dateComponents.nanosecond ?? 0) * 0.000001, 394.0, accuracy: 0.1)
    }
    
    func test_dateFromStringWithoutMilliseconds() {
        let dateString = "2019-02-25T03:09:53Z"
        guard let date = DateHelper.dateFrom(isoString: dateString) else {
            XCTFail("Parsed date not found.")
            return
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
        XCTAssertEqual(dateComponents.year, 2019)
        XCTAssertEqual(dateComponents.month, 2)
        XCTAssertEqual(dateComponents.day, 25)
        XCTAssertEqual(dateComponents.hour, 3)
        XCTAssertEqual(dateComponents.minute, 9)
        XCTAssertEqual(dateComponents.second, 53)
        XCTAssertEqual(dateComponents.nanosecond, 0)
    }
    
    func test_badIsoString() {
        let dateString = "March 3rd, 2019"
        let date = DateHelper.dateFrom(isoString: dateString)
        XCTAssertNil(date)
    }
    
    // MARK: - Timezones
    
    func test_safeTimezoneRealTimezone() {
        let realTimezoneIdentifier = "Europe/Zurich"
        let safeTimezone = DateHelper.getSafeTimezone(identifier: realTimezoneIdentifier)
        
        XCTAssertEqual(safeTimezone.identifier, realTimezoneIdentifier)
    }
    
    func test_safeTimezoneFakeTimezone() {
        let realTimezoneIdentifier = "America/Zurich"
        let safeTimezone = DateHelper.getSafeTimezone(identifier: realTimezoneIdentifier)
        
        let currentTimezone = TimeZone.autoupdatingCurrent
        
        XCTAssertEqual(safeTimezone.identifier, currentTimezone.identifier)
    }
    
    // MARK: - Date Ranges

    static func getStartOf(range: TimeRange, with incomingDateString: String) -> Date? {
        // Shared defaults of gregorian calendar in Chicago for all date range tests
        let calendarIdentifier: Calendar.Identifier = .gregorian
        let outputTimezone = "America/Chicago"
        
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: outputTimezone)

        guard
            let incomingDate = DateHelper.dateFrom(isoString: incomingDateString) else {
            return nil
        }
        
        let startOfRange = DateHelper.getStartOf(range, with: incomingDate, for: calendar)
        return startOfRange
    }
    
    static func evalute(incoming: String, against expected: String, with range: TimeRange) {
        guard
            let startOfRange = Test_DateHelper.getStartOf(range: range, with: incoming),
            let expectedResult = DateHelper.dateFrom(isoString: expected)
        else {
            XCTFail("Could not build test dates")
            return
        }

        XCTAssertEqual(startOfRange.timeIntervalSince1970, expectedResult.timeIntervalSince1970, accuracy: 1.0)
    }
  
    func test_getStartOfDay() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2021-01-15T06:00:00+00:00"
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: TimeRange(current: .day))
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: TimeRange(rolling: .day))
    }
    
    func test_startOfCurrentWeek() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2021-01-10T06:00:00+00:00"
        let timeRange = TimeRange(current: .week)
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: timeRange)
    }
    
    func test_startOfRollingWeek() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2021-01-08T06:00:00+00:00"
        let timeRange = TimeRange(rolling: .week)
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: timeRange)
    }
    
    func test_startOfCurrentMonth() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2021-01-01T06:00:00+00:00"
        let timeRange = TimeRange(current: .month)
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: timeRange)
    }
    
    func test_startOfRollingMonth() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2020-12-15T06:00:00+00:00"
        let timeRange = TimeRange(rolling: .month)
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: timeRange)
    }
    
    func test_startOfCurrentYear() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2021-01-01T06:00:00+00:00"
        let timeRange = TimeRange(current: .year)
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: timeRange)
    }
    
    func test_startOfRollingYear() {
        let incomingDateString = "2021-01-15T12:35:00-06:00"
        let expectedResultString = "2020-01-15T06:00:00+00:00"
        let timeRange = TimeRange(rolling: .year)
        
        Test_DateHelper.evalute(incoming: incomingDateString, against: expectedResultString, with: timeRange)
    }
}
