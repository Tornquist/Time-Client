//
//  Test_TimeRangeAndPeriod.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/24/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_TimeRangeAndPeriod: XCTestCase {
    func test_initCurrent() {
        let timeRange = TimeRange(current: .month)
        
        XCTAssertTrue(timeRange.isCurrent)
        XCTAssertFalse(timeRange.isRolling)
        XCTAssertEqual(timeRange.period, .month)
    }
    
    func test_initRolling() {
        let timeRange = TimeRange(rolling: .year)
        
        XCTAssertFalse(timeRange.isCurrent)
        XCTAssertTrue(timeRange.isRolling)
        XCTAssertEqual(timeRange.period, .year)
    }
}
