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

    // MARK: - Initialization and data loading
    
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
    
    func test_mismatchedColumnsInRow() {
        let inputFileName = "mismatched-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)

        let importer = FileImporter(fileURL: fileURL)
        
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
    
//    func test_all() {
//        let inputFileName = "import-example.csv"
//        let fileURL = self.getUrlInBundle(with: inputFileName)
//
//        let importer = FileImporter(fileURL: fileURL)
//
//        let startLoadData = CFAbsoluteTimeGetCurrent()
//        do {
//            try importer.loadData()
//            importer.categoryColumns = ["category", "project", "task", "subtask"]
//            try importer.buildCategoryTree()
//
//            // Parse Dates
//            let testFormat = "MMM d, y @ h:mm a zzz"
//
//            let validationSampleUnix = try importer.setDateTimeParseRules(
//                startUnixColumn: "unix_start",
//                endUnixColumn: "unix_end",
//                timezoneAbbreviation: "CST",
//                testFormat: testFormat
//            )
//
//            print("Unix Test Start: \(validationSampleUnix.startRaw ?? "??") to \(validationSampleUnix.startParsed ?? "??")")
//            print("Unix Test End: \(validationSampleUnix.endRaw ?? "??") to \(validationSampleUnix.endParsed ?? "??")")
//
//            let validationColumns = try importer.setDateTimeParseRules(
//                dateColumn: "date",
//                startTimeColumn: "start",
//                endTimeColumn: "end",
//                dateFormat: "M/d/yy",
//                timeFormat: "h:mm a",
//                timezoneAbbreviation: "CST",
//                testFormat: testFormat
//            )
//
//            print("Columns Test Start: \(validationColumns.startRaw ?? "??") to \(validationColumns.startParsed ?? "??")")
//            print("Columns Test End: \(validationColumns.endRaw ?? "??") to \(validationColumns.endParsed ?? "??")")
//
//            try importer.parseAll()
//
//            print("Total rows: \(importer.rows ?? -1)")
//            print("Total events: \(importer.events ?? -1)")
//            print("Total ranges: \(importer.ranges ?? -1)")
//        } catch {
//            print("Error loading data \(error)")
//            XCTFail()
//        }
//
//        let totalLoadData = CFAbsoluteTimeGetCurrent() - startLoadData
//        print("Took \(totalLoadData) seconds to load and process data")
//    }
}


class Test_FileImporter_Tree: XCTestCase {
    static var tree: FileImporter.Tree? = nil
    var tree: FileImporter.Tree! {
        get {
            return Test_FileImporter_Tree.tree
        }
        set {
            Test_FileImporter_Tree.tree = newValue
        }
    }
    
    func test_01_init() {
        let newTree = FileImporter.Tree(name: "Test")
        XCTAssertEqual(newTree.name, "Test")
        XCTAssertEqual(newTree.children.count, 0)
        XCTAssertEqual(newTree.events.count, 0)
        XCTAssertEqual(newTree.ranges.count, 0)
        
        self.tree = newTree
    }
    
    func test_02_buildingDescendants() {
        self.continueAfterFailure = false
        guard self.tree != nil else { XCTFail(); return }
        
        // Initial Building
        self.tree.buildDescendents(with: [
            "Cars", "Toyota"
        ])
        
        XCTAssertEqual(self.tree.children.count, 1)
        let firstChild = self.tree.children[0]
        XCTAssertEqual(firstChild.name, "Cars")
        XCTAssertEqual(firstChild.children.count, 1)
        
        let secondChild = firstChild.children[0]
        XCTAssertEqual(secondChild.name, "Toyota")
        XCTAssertEqual(secondChild.children.count, 0)
        
        // Deeper Building
        self.tree.buildDescendents(with: ["Cars", "Toyota", "Ram"])
        self.tree.buildDescendents(with: ["Cars", "Toyota", "Corolla"])
        self.tree.buildDescendents(with: ["Cars", "Ford"])
        self.tree.buildDescendents(with: ["Cars", "Ford"])
        self.tree.buildDescendents(with: ["Planes", "Boeing"])
        self.tree.buildDescendents(with: ["Planes", "Airbus"])
        
        /*
         Expected Tree:
         Cars
            Toyota
                Ram
                Corolla
            Ford
         Planes
            Boeing
            Airbus
         */
        
        let getChild = { (tree: FileImporter.Tree?, name: String) -> (FileImporter.Tree?) in
            guard tree != nil else { return nil }

            return tree!.children.first(where: { (child) -> Bool in
                return child.name == name
            })
        }
        
        let testTree = { (tree: FileImporter.Tree?, isNil: Bool, name: String, numChildren: Int) -> () in
            if (isNil) {
                XCTAssertNil(tree, "Expected tree with name \(name) to be nil")
            } else {
                XCTAssertNotNil(tree, "Expected tree with name \(tree?.name ?? "??") to not be nil")
                XCTAssertEqual(tree?.name, name, "Expected tree with name \(tree?.name ?? "??") to have name \(name)")
                XCTAssertEqual(tree?.children.count, numChildren, "Expected tree with name \(tree?.name ?? "??") to have \(numChildren) children")
            }
        }
        
        // Root
        XCTAssertEqual(self.tree.children.count, 2)
        let cars = getChild(self.tree, "Cars")
        testTree(cars, false, "Cars", 2)
        
        let planes = getChild(self.tree, "Planes")
        testTree(planes, false, "Planes", 2)
        
        // Second
        let toyota = getChild(cars, "Toyota")
        let ford = getChild(cars, "Ford")
        let dodge = getChild(cars, "Dodge")
        testTree(toyota, false, "Toyota", 2)
        testTree(ford, false, "Ford", 0)
        testTree(dodge, true, "Dodge", 0)
        
        let boeing = getChild(planes, "Boeing")
        let airbus = getChild(planes, "Airbus")
        testTree(boeing, false, "Boeing", 0)
        testTree(airbus, false, "Airbus", 0)
        
        // Third
        let ram = getChild(toyota, "Ram")
        let corolla = getChild(toyota, "Corolla")
        testTree(ram, false, "Ram", 0)
        testTree(corolla, false, "Corolla", 0)
    }
    
    func test_03_storingAndCountingEvents() {
        self.continueAfterFailure = false
        guard self.tree != nil else { XCTFail(); return }
        
        let allEntries = self.tree.count(events: true, ranges: true)
        XCTAssertEqual(allEntries, 0)
        
        // Add one event
        self.tree.store(start: Date(), andEnd: nil, with: ["Cars", "Toyota", "Ram"])
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 1)
        XCTAssertEqual(self.tree.count(events: true, ranges: false), 1)
        XCTAssertEqual(self.tree.count(events: false, ranges: true), 0)

        // Add one range
        self.tree.store(start: Date(), andEnd: Date(), with: ["Planes"])
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 2)
        XCTAssertEqual(self.tree.count(events: true, ranges: false), 1)
        XCTAssertEqual(self.tree.count(events: false, ranges: true), 1)
        
        // Fail to add two events (no matching item in tree)
        self.tree.store(start: Date(), andEnd: Date(), with: ["Planes", "NotReal"])
        self.tree.store(start: Date(), andEnd: Date(), with: ["NotReal"])
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 2)
        XCTAssertEqual(self.tree.count(events: true, ranges: false), 1)
        XCTAssertEqual(self.tree.count(events: false, ranges: true), 1)
        
        // Add 1 range and 2 events
        self.tree.store(start: Date(), andEnd: Date(), with: ["Cars"])
        self.tree.store(start: Date(), andEnd: nil, with: ["Cars", "Ford"])
        self.tree.store(start: Date(), andEnd: nil, with: ["Planes", "Boeing"])
        
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 5)
        XCTAssertEqual(self.tree.count(events: true, ranges: false), 3)
        XCTAssertEqual(self.tree.count(events: false, ranges: true), 2)
    }
    
    func test_04_clearStructure() {
        self.continueAfterFailure = false
        guard self.tree != nil else { XCTFail(); return }
        
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 5)
                
        // Clean all data at and under cars
        guard let cars = self.tree.children.first(where: { $0.name == "Cars" }) else {
            XCTFail()
            return
        }

        XCTAssertEqual(cars.count(events: true, ranges: true), 3)
        cars.cleanStructure()
        XCTAssertEqual(cars.count(events: true, ranges: true), 0)
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 2)
        
        // Clean all data
        self.tree.cleanStructure()
        XCTAssertEqual(self.tree.count(events: true, ranges: true), 0)
    }
}
