//
//  Test_Analyzer.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/24/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_Analyzer: XCTestCase {
    
    // MARK: - Shared
    
    static var analyzer: Analyzer!
    var analyzer: Analyzer! {
        return type(of: self).analyzer
    }
    
    override class func setUp() {
        // Load seed data
        let inputFileName = "test-analytics.json"
        let fileParts = inputFileName.split(separator: ".").map({ String($0) })
        let bundle = Bundle(for: Test_Analyzer.self)
        guard let fileURL = bundle.url(forResource: fileParts[0], withExtension: fileParts[1]),
              let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([Entry].self, from: data)
        else {
            XCTFail("Error loading data")
            return
        }
        
        // Build store
        let api = API()
        let store = Store(api: api)
        store.entries = entries
                
        // Build analyzer
        Test_Analyzer.analyzer = Analyzer(store: store)
    }
    
    func test_entireMonthTotalOnly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }
        
        let results = self.analyzer.evaluate(
            from: startDate,
            to: endDate,
            in: calendar,
            groupBy: .month,
            perform: [.calculateTotal]
        )
        
        XCTAssertEqual(results.keys.count, 1)
        guard let firstKey = results.keys.first else {
            XCTFail("Failed to find first key")
            return
        }
        
        XCTAssertEqual(firstKey, "2020-11-01")
        XCTAssertEqual(results[firstKey]!.count, 1)
        
        guard let firstOperation = results[firstKey]?.first else {
            XCTFail("Failed to find first operation")
            return
        }
        
        XCTAssertEqual(firstOperation.operation, .calculateTotal)
        XCTAssertEqual(firstOperation.duration, 675927)
        XCTAssertEqual(firstOperation.events, 6)
        XCTAssertEqual(firstOperation.categoryID, nil)
        XCTAssertEqual(firstOperation.open, false)
    }
    
    func test_entireMonthByCategory() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }
        
        let results = self.analyzer.evaluate(
            from: startDate,
            to: endDate,
            in: calendar,
            groupBy: .month,
            perform: [.calculatePerCategory]
        )
        
        XCTAssertEqual(results.keys.count, 1)
        guard let firstKey = results.keys.first else {
            XCTFail("Failed to find first key")
            return
        }
        
        XCTAssertEqual(firstKey, "2020-11-01")
        
        guard let operationResults = results.values.first else {
            XCTFail("Failed to build results")
            return
        }
        
        XCTAssertEqual(operationResults.count, 5) // 5 categories in Nov
        
        operationResults.forEach { (result) in
            XCTAssertEqual(result.operation, .calculatePerCategory)
            XCTAssertEqual(result.open, false)
            switch result.categoryID {
            case 5:
                XCTAssertEqual(result.duration, 2195)
                XCTAssertEqual(result.events, 0)
            case 14:
                XCTAssertEqual(result.duration, 593)
                XCTAssertEqual(result.events, 0)
            case 28:
                XCTAssertEqual(result.duration, 2757)
                XCTAssertEqual(result.events, 0)
            case 37:
                XCTAssertEqual(result.duration, 3772)
                XCTAssertEqual(result.events, 2)
            case 38:
                XCTAssertEqual(result.duration, 666610)
                XCTAssertEqual(result.events, 4)
            default:
                XCTFail("Unknown category id")
            }
        }
    }
    
    func test_yearWithCategoryAndTotal() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }
        
        // This search will group by year, but still limit the values to November.
        // The results will match what was seen above.
        let results = self.analyzer.evaluate(
            from: startDate,
            to: endDate,
            in: calendar,
            groupBy: .year,
            perform: [.calculateTotal, .calculatePerCategory]
        )
        
        XCTAssertEqual(results.keys.count, 1)
        guard let firstKey = results.keys.first else {
            XCTFail("Failed to find first key")
            return
        }
        
        XCTAssertEqual(firstKey, "2020-01-01")
        
        guard let completeResults = results.values.first else {
            XCTFail("Failed to build results")
            return
        }
        
        let totalResults = completeResults.filter({ $0.operation == .calculateTotal })
        let categoryResults = completeResults.filter({ $0.operation == .calculatePerCategory })
        
        XCTAssertEqual(totalResults.count, 1) // Single total entry
        XCTAssertEqual(categoryResults.count, 5) // 5 categories in Nov
        
        categoryResults.forEach { (result) in
            XCTAssertEqual(result.operation, .calculatePerCategory)
            XCTAssertEqual(result.open, false)
            switch result.categoryID {
            case 5:
                XCTAssertEqual(result.duration, 2195)
                XCTAssertEqual(result.events, 0)
            case 14:
                XCTAssertEqual(result.duration, 593)
                XCTAssertEqual(result.events, 0)
            case 28:
                XCTAssertEqual(result.duration, 2757)
                XCTAssertEqual(result.events, 0)
            case 37:
                XCTAssertEqual(result.duration, 3772)
                XCTAssertEqual(result.events, 2)
            case 38:
                XCTAssertEqual(result.duration, 666610)
                XCTAssertEqual(result.events, 4)
            default:
                XCTFail("Unknown category id")
            }
        }
    }
    
    func test_weeklyTotals() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: "America/Chicago")
        guard
            let startDate = DateHelper.dateFrom(isoString: "2020-10-31T12:35:00-06:00"),
            let endDate = DateHelper.dateFrom(isoString: "2020-12-01T12:35:00-06:00")
        else {
            XCTFail("Could not build test dates")
            return
        }
        
        // This search will group by year, but still limit the values to November.
        // The results will match what was seen above.
        let results = self.analyzer.evaluate(
            from: startDate,
            to: endDate,
            in: calendar,
            groupBy: .week,
            perform: [.calculateTotal]
        )
        
        XCTAssertEqual(results.keys.count, 5)

        let expectedKeys = ["2020-11-01", "2020-11-08", "2020-11-15", "2020-11-22", "2020-11-29"]
        XCTAssertEqual(Set(results.keys), Set(expectedKeys))
        
        results.forEach { (record) in
            let date = record.key
            let weekResults = record.value
            
            XCTAssertEqual(weekResults.count, 1)
            guard let totalInWeek = weekResults.first else {
                XCTFail("Could not get weekly results")
                return
            }
            
            XCTAssertEqual(totalInWeek.operation, .calculateTotal)
            XCTAssertEqual(totalInWeek.open, false)
            
            switch date {
            case "2020-11-01":
                XCTAssertEqual(totalInWeek.duration, 154671) // ~42.96
                XCTAssertEqual(totalInWeek.events, 2)
            case "2020-11-08":
                XCTAssertEqual(totalInWeek.duration, 174440) // ~48.45
                XCTAssertEqual(totalInWeek.events, 1)
            case "2020-11-15":
                XCTAssertEqual(totalInWeek.duration, 173543) // ~48.20
                XCTAssertEqual(totalInWeek.events, 1)
            case "2020-11-22":
                XCTAssertEqual(totalInWeek.duration, 118142) // ~48.20
                XCTAssertEqual(totalInWeek.events, 0)
            case "2020-11-29":
                XCTAssertEqual(totalInWeek.duration, 55131) // ~ 32.82
                XCTAssertEqual(totalInWeek.events, 2)
            default:
                XCTFail("Unknown category id")
            }
        }
    }
    
    func test_openAnalysis() {
        let tz = "America/Chicago"
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DateHelper.getSafeTimezone(identifier: tz)
        
        let now = Date()
        
        let startOfToday = calendar.startOfDay(for: now)
        
        guard
            let base = calendar.date(byAdding: DateComponents(hour: -12), to: startOfToday),
            
            let presentStart = calendar.date(byAdding: DateComponents(hour: -2), to: startOfToday),
            
            // 2 hr, 13 min (7980)
            let todayStart = calendar.date(byAdding: DateComponents(day: 1, hour: -1), to: base),
            let todayEnd = calendar.date(byAdding: DateComponents(day: 1, hour: 1, minute: 13), to: base),
            
            // 3 hr, 25 min (12300s)
            let yesterdayStart = calendar.date(byAdding: DateComponents(hour: -2, minute: -15), to: base),
            let yesterdayEnd = calendar.date(byAdding: DateComponents(hour: 1, minute: 10), to: base),
            
            // 2 hr, 5 min (7500s)
            let twoDaysAgoStart = calendar.date(byAdding: DateComponents(day: -1, minute: 10), to: base),
            let twoDaysAgoEnd = calendar.date(byAdding: DateComponents(day: -1, hour: 2, minute: 15), to: base),
            
            // 5 hr, 31 min (19860s)
            let threeDaysAgoStart = calendar.date(byAdding: DateComponents(day: -2, hour: -2, minute: -15), to: base),
            let threeDaysAgoEnd = calendar.date(byAdding: DateComponents(day: -2, hour: 3, minute: 16), to: base),
            
            // 1 min (60s)
            let fourDaysAgoStart = calendar.date(byAdding: DateComponents(day: -3), to: base),
            let fourDaysAgoEnd = calendar.date(byAdding: DateComponents(day: -3, minute: 1), to: base),
            
            // 6 hr (21600s)
            let tenDaysAgoStart = calendar.date(byAdding: DateComponents(day: -9, hour: -5), to: base),
            let tenDaysAgoEnd = calendar.date(byAdding: DateComponents(day: -9, hour: 1), to: base)
        else {
            XCTFail("Could not build entry seed dates")
            return
        }
        
        let entries: [Entry] = [
            //Today open
            Entry(id: 100000, type: .range, categoryID: 1, startedAt: presentStart, startedAtTimezone: tz, endedAt: nil),
            // Today closed
            Entry(id: 100001, type: .range, categoryID: 1, startedAt: todayStart, startedAtTimezone: tz, endedAt: todayEnd, endedAtTimezone: tz),
            // Past closed
            Entry(id: 100002, type: .range, categoryID: 1, startedAt: yesterdayStart, startedAtTimezone: tz, endedAt: yesterdayEnd, endedAtTimezone: tz),
            Entry(id: 100003, type: .range, categoryID: 1, startedAt: twoDaysAgoStart, startedAtTimezone: tz, endedAt: twoDaysAgoEnd, endedAtTimezone: tz),
            Entry(id: 100004, type: .range, categoryID: 1, startedAt: threeDaysAgoStart, startedAtTimezone: tz, endedAt: threeDaysAgoEnd, endedAtTimezone: tz),
            Entry(id: 100005, type: .range, categoryID: 1, startedAt: fourDaysAgoStart, startedAtTimezone: tz, endedAt: fourDaysAgoEnd, endedAtTimezone: tz),
            Entry(id: 100006, type: .range, categoryID: 1, startedAt: tenDaysAgoStart, startedAtTimezone: tz, endedAt: tenDaysAgoEnd, endedAtTimezone: tz) // will be ignored
        ]
        
        // Build store
        let api = API()
        let store = Store(api: api)
        store.entries = entries
                
        // Build analyzer
        let analyzer = Analyzer(store: store)
        
        // Test
        let results = analyzer.evaluate(
            TimeRange(rolling: .week),
            in: calendar,
            groupBy: .day,
            perform: [.calculateTotal]
        )
        
        XCTAssertEqual(results.keys.count, 5)
        
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        
        let day1 = formatter.string(from: startOfToday)
        let day2 = formatter.string(from: entries[2].startedAt)
        let day3 = formatter.string(from: entries[3].startedAt)
        let day4 = formatter.string(from: entries[4].startedAt)
        let day5 = formatter.string(from: entries[5].startedAt)
        
        XCTAssertEqual(Set([day1, day2, day3, day4, day5]), Set(results.keys))
        
        let day1Duration = now.timeIntervalSinceReferenceDate - startOfToday.timeIntervalSinceReferenceDate + 7980
        let day2Duration: TimeInterval = 12300 /* day 2 */ + 7200 /* early morning day 1 */
        let day3Duration: TimeInterval = 7500
        let day4Duration: TimeInterval = 19860
        let day5Duration: TimeInterval = 60
        
        XCTAssertEqual(results[day1]?.first?.duration ?? 0, day1Duration, accuracy: 1.0)
        XCTAssertEqual(results[day1]?.first?.events ?? 0, 0)
        XCTAssertEqual(results[day1]?.first?.open ?? false, true)
        
        XCTAssertEqual(results[day2]?.first?.duration ?? 0, day2Duration)
        XCTAssertEqual(results[day2]?.first?.events ?? 0, 0)
        XCTAssertEqual(results[day2]?.first?.open ?? true, false)
        
        XCTAssertEqual(results[day3]?.first?.duration ?? 0, day3Duration)
        XCTAssertEqual(results[day3]?.first?.events ?? 0, 0)
        XCTAssertEqual(results[day3]?.first?.open ?? true, false)
        
        XCTAssertEqual(results[day4]?.first?.duration ?? 0, day4Duration)
        XCTAssertEqual(results[day4]?.first?.events ?? 0, 0)
        XCTAssertEqual(results[day4]?.first?.open ?? true, false)
        
        XCTAssertEqual(results[day5]?.first?.duration ?? 0, day5Duration)
        XCTAssertEqual(results[day5]?.first?.events ?? 0, 0)
        XCTAssertEqual(results[day5]?.first?.open ?? true, false)
    }
}
