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
    func getUrlInBundle(with name: String) -> URL {
        let fileParts = name.split(separator: ".").map({ String($0) })
        let bundle = Bundle(for: type(of: self))
        let fileURL = bundle.url(forResource: fileParts[0], withExtension: fileParts[1])!
        
        return fileURL
    }
    
    func test_initWithInvalidPath() {
        guard var fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail()
            return
        }
        fileURL.appendPathComponent("not-a-real-file.csv")
        
        let importer = FileImporter(fileURL: fileURL)
        
        XCTAssertThrowsError(try importer.loadData()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.fileNotFound)
        }
    }
    
    func test_badFileContent() {
        let inputFileName = "not-a-csv.png"
        let fileURL = self.getUrlInBundle(with: inputFileName)

        let importer = FileImporter(fileURL: fileURL)
        
        XCTAssertThrowsError(try importer.loadData()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.unableToReadFile)
        }
    }
    
    func test_badFileLength() {
        let inputFileName = "tiny-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)

        let importer = FileImporter(fileURL: fileURL)
        
        XCTAssertThrowsError(try importer.loadData()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.unableToParseCSV)
        }
    }
    
    func test_badSeparator() {
        let inputFileName = "import-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)

        let importer = FileImporter(fileURL: fileURL, separator: "|")
        
        XCTAssertThrowsError(try importer.loadData()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.unableToParseCSV)
        }
    }
    
    func test_successfulLoad() {
        let inputFileName = "import-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)
        let importer = FileImporter(fileURL: fileURL, separator: ",")
        
        XCTAssertEqual(importer.columns?.count ?? 0, 0)
        XCTAssertNoThrow(try importer.loadData())
        XCTAssertGreaterThan(importer.columns?.count ?? 0, 0)
        
        let expectedColumns = Set([
            "type",
            "date",
            "unix_start",
            "unix_end",
            "day",
            "start",
            "end",
            "category",
            "project",
            "task",
            "subtask",
            "amount",
            "amount_decimal",
            "rate",
            "sum",
            "rounding_minutes",
            "rounding_method",
            "note"
        ])
        let actualColumns = Set(importer.columns ?? [])
        
        XCTAssertEqual(expectedColumns, actualColumns)
    }
    
    func test_all() {
        let inputFileName = "import-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)

        let importer = FileImporter(fileURL: fileURL)

        let startLoadData = CFAbsoluteTimeGetCurrent()
        do {
            try importer.loadData()
            importer.categoryColumns = ["category", "project", "task", "subtask"]
            try importer.buildCategoryTree()
            
            // Parse Dates
            let testFormat = "MMM d, y @ h:mm a zzz"
            
            let validationSampleUnix = try importer.setDateTimeParseRules(
                startUnixColumn: "unix_start",
                endUnixColumn: "unix_end",
                timezoneAbbreviation: "CST",
                testFormat: testFormat
            )

            print("Unix Test Start: \(validationSampleUnix.startRaw ?? "??") to \(validationSampleUnix.startParsed ?? "??")")
            print("Unix Test End: \(validationSampleUnix.endRaw ?? "??") to \(validationSampleUnix.endParsed ?? "??")")
                        
            let validationColumns = try importer.setDateTimeParseRules(
                dateColumn: "date",
                startTimeColumn: "start",
                endTimeColumn: "end",
                dateFormat: "M/d/yy",
                timeFormat: "h:mm a",
                timezoneAbbreviation: "CST",
                testFormat: testFormat
            )
            
            print("Columns Test Start: \(validationColumns.startRaw ?? "??") to \(validationColumns.startParsed ?? "??")")
            print("Columns Test End: \(validationColumns.endRaw ?? "??") to \(validationColumns.endParsed ?? "??")")
            
            try importer.parseAll()
            
            print("Total rows: \(importer.rows ?? -1)")
            print("Total events: \(importer.events ?? -1)")
            print("Total ranges: \(importer.ranges ?? -1)")
        } catch {
            print("Error loading data \(error)")
            XCTFail()
        }

        let totalLoadData = CFAbsoluteTimeGetCurrent() - startLoadData
        print("Took \(totalLoadData) seconds to load and process data")
    }
}
