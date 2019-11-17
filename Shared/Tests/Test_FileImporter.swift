//
//  Test_FileImporter.swift
//  Shared
//
//  Created by Nathan Tornquist on 11/10/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_FileImporter: XCTestCase {
    func test_all() {
        let inputFileName = "import-example.csv"
        
        let fileParts = inputFileName.split(separator: ".").map({ String($0) })
        let bundle = Bundle(for: type(of: self))
        let fileURL = bundle.url(forResource: fileParts[0], withExtension: fileParts[1])!

        let importer = FileImporter(fileURL: fileURL)

        let startLoadData = CFAbsoluteTimeGetCurrent()
        do {
            try importer.loadData()
            importer.categoryColumns = ["category", "project", "task", "subtask"]
            try importer.buildCategoryTree()
            
            try importer.setDateTimeParseRules(
                startUnixColumn: "unix_start",
                endUnixColumn: "unix_end",
                timezoneAbbreviation: "CST"
            )
            
            try importer.setDateTimeParseRules(
                dateColumn: "date",
                startTimeColumn: "start",
                endTimeColumn: "end",
                dateFormat: "M/d/yy",
                timeFormat: "h:mm a",
                timezoneAbbreviation: "CST"
            )
        } catch {
            print("Error loading data \(error)")
            XCTFail()
        }

        let totalLoadData = CFAbsoluteTimeGetCurrent() - startLoadData
        print("Took \(totalLoadData) seconds to load and process data")
    }
}
