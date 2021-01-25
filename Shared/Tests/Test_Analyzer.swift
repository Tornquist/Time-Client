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
            case 14:
                XCTAssertEqual(result.duration, 593)
            case 28:
                XCTAssertEqual(result.duration, 2757)
            case 37:
                XCTAssertEqual(result.duration, 3772)
            case 38:
                XCTAssertEqual(result.duration, 666610)
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
            case 14:
                XCTAssertEqual(result.duration, 593)
            case 28:
                XCTAssertEqual(result.duration, 2757)
            case 37:
                XCTAssertEqual(result.duration, 3772)
            case 38:
                XCTAssertEqual(result.duration, 666610)
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
            case "2020-11-08":
                XCTAssertEqual(totalInWeek.duration, 174440) // ~48.45
            case "2020-11-15":
                XCTAssertEqual(totalInWeek.duration, 173543) // ~48.20
            case "2020-11-22":
                XCTAssertEqual(totalInWeek.duration, 118142) // ~48.20
            case "2020-11-29":
                XCTAssertEqual(totalInWeek.duration, 55131) // ~ 32.82
            default:
                XCTFail("Unknown category id")
            }
        }
    }
}
