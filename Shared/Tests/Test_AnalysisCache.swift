//
//  Test_AnalysisCache.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/24/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_AnalysisCache: XCTestCase {
    
    // MARK: - Shared
    
    static var cache: AnalysisCache!
    var cache: AnalysisCache! {
        return Test_AnalysisCache.cache
    }
    
    override class func setUp() {
        // Load seed data
        let inputFileName = "test-analytics.json"
        let fileParts = inputFileName.split(separator: ".").map({ String($0) })
        let bundle = Bundle(for: Test_AnalysisCache.self)
        guard let fileURL = bundle.url(forResource: fileParts[0], withExtension: fileParts[1]),
              let data = try? Data(contentsOf: fileURL),
              let result = try? JSONDecoder().decode([Entry].self, from: data)
        else {
            XCTFail("Error loading data")
            return
        }
        
        // Evaluate data
        let analysis = result.map({ EntryAnalysis.generate(for: $0) })
        
        // Create cache
        Test_AnalysisCache.cache = AnalysisCache(from: analysis)
    }
    
    // MARK: - Tests
    
    func test_getSingleDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-11-03T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-11-04T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }

        let sameDay = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: startDate,
            groupingBy: .day,
            with: calendar)
        let endNextDay = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: endDate,
            groupingBy: .day,
            with: calendar)
        let noEnd = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: nil,
            groupingBy: .day,
            with: calendar)
        
        // Time search is start inclusive and end exclusive. A single day
        // requires a search of the start, and exclusion of tomorrow
        
        XCTAssertEqual(sameDay.count, 0)
        XCTAssertEqual(noEnd.count, 23) // All data in cache
        
        XCTAssertEqual(endNextDay.count, 1)
        XCTAssertEqual(endNextDay.keys.first ?? "--", "2020-11-03")
        
        guard let singleDay = endNextDay.values.first else {
            XCTFail("Cannot get data for single day")
            return
        }
        
        XCTAssertEqual(singleDay.count, 4)
        let totalDayDuration = singleDay.reduce(0, { $0 + $1.duration })
        XCTAssertEqual(totalDayDuration, 29347, accuracy: 1.0)
        
        let hoursEstimate = totalDayDuration / 60 / 60
        XCTAssertEqual(hoursEstimate, 8.15, accuracy: 0.01)
    }
    
    func test_wholeRangeByDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }

        let dataByDay = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: endDate,
            groupingBy: .day,
            with: calendar)
        
        XCTAssertEqual(dataByDay.count, 24) // Data exists for 24 days
    }
    
    func test_wholeRangeByWeek() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }

        let dataByWeek = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: endDate,
            groupingBy: .week, // All grouping is start of X. TimeRange is for search
            with: calendar)
        
        XCTAssertEqual(dataByWeek.count, 5)
        
        let expectedKeys = ["2020-11-01", "2020-11-08", "2020-11-15", "2020-11-22", "2020-11-29"]
        
        XCTAssertEqual(Set(dataByWeek.keys), Set(expectedKeys))
        
        // An entry exists at 0:26 GMT on the 30th that was previously rolling
        // to the week of the 22nd. This boarder (and association) must be verified.
        
        // This was resolved by parsing the cache keys in the same calendar
        // they are used in. Otherwise start time (00:00) can cause day shifts.
        
        guard let finalWeek = dataByWeek["2020-11-29"] else {
            XCTFail("Could not get final week data")
            return
        }
        
        XCTAssertEqual(finalWeek.count, 3)
        
        let expectedIDs = [3126, 3127, 3128]
        XCTAssertEqual(Set(finalWeek.map({ $0.entryID })), Set(expectedIDs))
        
        let expectedDurations: [TimeInterval] = [1980.0, 18022.0, 35129.0]
        XCTAssertEqual(Set(finalWeek.map({ $0.duration })), Set(expectedDurations))
    }
    
    func test_wholeRangeByMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }

        let dataByMonth = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: endDate,
            groupingBy: .month,
            with: calendar)
        
        XCTAssertEqual(dataByMonth.count, 1)
        XCTAssertEqual(dataByMonth.keys.first, "2020-11-01")
    }
    
    func test_wholeRangeByYear() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }

        let dataByYear = self.cache.getGroupedSplits(
            searchingFrom: startDate,
            to: endDate,
            groupingBy: .year,
            with: calendar)
        
        XCTAssertEqual(dataByYear.count, 1)
        XCTAssertEqual(dataByYear.keys.first, "2020-01-01")
    }
}
