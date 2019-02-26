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
        self.continueAfterFailure = false
        let dateString = "2019-02-25T03:09:53Z"
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
        XCTAssertEqual(dateComponents.nanosecond, 0)
    }
    
    func test_badIsoString() {
        let dateString = "March 3rd, 2019"
        let date = DateHelper.dateFrom(isoString: dateString)
        XCTAssertNil(date)
    }
}
