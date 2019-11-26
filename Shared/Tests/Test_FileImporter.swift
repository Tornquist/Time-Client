//
//  Test_FileImporter.swift
//  Shared
//
//  Created by Nathan Tornquist on 11/10/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_FileImporterShared: XCTestCase {
    func getChild(tree: FileImporter.Tree?, name: String) -> (FileImporter.Tree?) {
        guard tree != nil else { return nil }

        return tree!.children.first(where: { (child) -> Bool in
            return child.name == name
        })
    }
    
    func testTree(tree: FileImporter.Tree?, isNil: Bool, name: String, numChildren: Int) {
        if (isNil) {
            XCTAssertNil(tree, "Expected tree with name \(name) to be nil")
        } else {
            XCTAssertNotNil(tree, "Expected tree with name \(tree?.name ?? "??") to not be nil")
            XCTAssertEqual(tree?.name, name, "Expected tree with name \(tree?.name ?? "??") to have name \(name)")
            XCTAssertEqual(tree?.children.count, numChildren, "Expected tree with name \(tree?.name ?? "??") to have \(numChildren) children")
        }
    }
    
    struct ImporterData: Codable {
        var name: String
        var events: [[String:String]]
        var ranges: [[String:String]]
        var children: [ImporterData]
    }
}

class Test_FileImporter: Test_FileImporterShared {
    func getUrlInBundle(with name: String) -> URL {
        let fileParts = name.split(separator: ".").map({ String($0) })
        let bundle = Bundle(for: type(of: self))
        let fileURL = bundle.url(forResource: fileParts[0], withExtension: fileParts[1])!
        
        return fileURL
    }
    
    func getImporterWithData() -> FileImporter {
        let inputFileName = "import-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)
        let importer = FileImporter(fileURL: fileURL, separator: ",")
        XCTAssertNoThrow(try importer.loadData())
        return importer
    }
    
    // MARK: - Initialization and Data Loading
    
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
    
    // MARK: - Building Category Tree
    
    func test_buildingTreeWithoutSettingColumns() {
        let importer = self.getImporterWithData()
        XCTAssertThrowsError(try importer.buildCategoryTree()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.categoryColumnsNotSpecified)
        }
    }
    
    func test_buildingTreeWithMadeUpColumns() {
        let importer = self.getImporterWithData()
        importer.categoryColumns = ["not-in-csv"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        
        XCTAssertNotNil(importer.categoryTree)
        XCTAssertEqual(importer.categoryTree?.children.count, 0)
    }
    
    func test_buildingTreeWithSingleColumns() {
        self.continueAfterFailure = false
        
        let importer = self.getImporterWithData()
        importer.categoryColumns = ["category"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        
        XCTAssertNotNil(importer.categoryTree)
        XCTAssertEqual(importer.categoryTree?.children.count, 3)
        
        let childrenNames = Set(importer.categoryTree!.children.map({ $0.name }))
        XCTAssertEqual(childrenNames, Set(["Life", "Work", "Side Projects"]))
        
        importer.categoryTree!.children.forEach { (child) in
            XCTAssertEqual(child.children.count, 0)
        }
    }
    
    func test_buildingAFullCategoryTree() {
        self.continueAfterFailure = false
        
        let importer = self.getImporterWithData()
        importer.categoryColumns = ["category", "project", "task", "subtask"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        
        XCTAssertNotNil(importer.categoryTree)
        XCTAssertEqual(importer.categoryTree?.children.count, 3)
        
        let childrenNames = Set(importer.categoryTree!.children.map({ $0.name }))
        XCTAssertEqual(childrenNames, Set(["Life", "Work", "Side Projects"]))
        
        /*
         Expected Tree:
         Work
            Real Job
                Core Project
         Side Projects
            SAAS Startup
                Idea 1
         Life
            Trumpet
                Practice
         */
        
        // Root
        let work = getChild(tree: importer.categoryTree, name: "Work")
        let sideProjects = getChild(tree: importer.categoryTree, name: "Side Projects")
        let life = getChild(tree: importer.categoryTree, name: "Life")
        
        testTree(tree: work, isNil: false, name: "Work", numChildren: 1)
        testTree(tree: sideProjects, isNil: false, name: "Side Projects", numChildren: 1)
        testTree(tree: life, isNil: false, name: "Life", numChildren: 1)
        
        // Level 1
        let realJob = getChild(tree: work, name: "Real Job")
        let saasStartup = getChild(tree: sideProjects, name: "SAAS Startup")
        let trumpet = getChild(tree: life, name: "Trumpet")
        
        testTree(tree: realJob, isNil: false, name: "Real Job", numChildren: 1)
        testTree(tree: saasStartup, isNil: false, name: "SAAS Startup", numChildren: 1)
        testTree(tree: trumpet, isNil: false, name: "Trumpet", numChildren: 1)
        
        // Level 2
        let coreProject = getChild(tree: realJob, name: "Core Project")
        let idea1 = getChild(tree: saasStartup, name: "Idea 1")
        let practice = getChild(tree: trumpet, name: "Practice")
        
        testTree(tree: coreProject, isNil: false, name: "Core Project", numChildren: 0)
        testTree(tree: idea1, isNil: false, name: "Idea 1", numChildren: 0)
        testTree(tree: practice, isNil: false, name: "Practice", numChildren: 0)
    }
    
    // MARK: - Setting Date/Time Input Formats
    
    func test_settingDateTimeRulesBeforeLoadingData() {
        let inputFileName = "import-example.csv"
        let fileURL = self.getUrlInBundle(with: inputFileName)

        let importer = FileImporter(fileURL: fileURL)
        
        XCTAssertThrowsError(try importer.setDateTimeParseRules(
            startUnixColumn: "unix_start",
            endUnixColumn: "unix_end"
        )) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.missingObjectData)
        }
    }
    
    func test_settingDatetimeRulesFromUnixTimestamps() {
        self.continueAfterFailure = false
        
        let importer = self.getImporterWithData()
        do {
            let res = try importer.setDateTimeParseRules(
                startUnixColumn: "unix_start",
                endUnixColumn: "unix_end",
                timezoneAbbreviation: "CST",
                testFormat: "MMM d, y @ h:mm a zzz"
            )
            
            // Returns a single parsed pair (as an example of the result)
            XCTAssertNotNil(res.startRaw)
            XCTAssertEqual(res.startParsed, "Aug 1, 2016 @ 8:38 AM CDT")
            XCTAssertNotNil(res.endRaw)
            XCTAssertEqual(res.endParsed, "Aug 1, 2016 @ 12:33 PM CDT")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_settingDatetimeRulesFromDateAndTimeColumns() {
        self.continueAfterFailure = false
        
        let importer = self.getImporterWithData()
        do {
            let res = try importer.setDateTimeParseRules(
                dateColumn: "date",
                startTimeColumn: "start",
                endTimeColumn: "end",
                dateFormat: "M/d/yy",
                timeFormat: "h:mm a",
                timezoneAbbreviation: "CST",
                testFormat: "MMM d, y @ h:mm a zzz"
            )
            
            // Returns a single parsed pair (as an example of the result)
            XCTAssertNotNil(res.startRaw)
            XCTAssertEqual(res.startParsed, "Aug 1, 2016 @ 8:38 AM CDT")
            XCTAssertNotNil(res.endRaw)
            XCTAssertEqual(res.endParsed, "Aug 1, 2016 @ 12:33 PM CDT")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_settingDatetimeRulesWithDifferentTimezones() {
        self.continueAfterFailure = false
        
        let importer = self.getImporterWithData()
        do {
            let res = try importer.setDateTimeParseRules(
                dateColumn: "date",
                startTimeColumn: "start",
                endTimeColumn: "end",
                dateFormat: "M/d/yy",
                timeFormat: "h:mm a",
                timezoneAbbreviation: "EST", // General. Will set EDT/EST in output
                testFormat: "h:mm a zzz" // Using custom output format
            )
            
            // Returns a single parsed pair (as an example of the result)
            XCTAssertNotNil(res.startRaw)
            XCTAssertEqual(res.startParsed, "8:38 AM EDT")
            XCTAssertNotNil(res.endRaw)
            XCTAssertEqual(res.endParsed, "12:33 PM EDT")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    // MARK: - Parsing All Data
    
    func test_rejectsWithoutDatetimeSettings() {
        self.continueAfterFailure = false
        
        let importer = self.getImporterWithData()
        importer.categoryColumns = ["category", "project", "task", "subtask"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        
        XCTAssertThrowsError(try importer.parseAll()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.setupNotCompleted)
        }
    }

    func test_rejectsWithoutParsedCategories() {
        self.continueAfterFailure = false

        let importer = self.getImporterWithData()
        XCTAssertNoThrow(try importer.setDateTimeParseRules(
            startUnixColumn: "unix_start",
            endUnixColumn: "unix_end",
            timezoneAbbreviation: "CST",
            testFormat: "MMM d, y @ h:mm a zzz"
        ))

        XCTAssertThrowsError(try importer.parseAll()) { (error) in
            XCTAssertEqual(error as? FileImporterError, FileImporterError.setupNotCompleted)
        }
    }
    
    func test_parsesAllDataWithSetupCompleted() {
        self.continueAfterFailure = false

        let importer = self.getImporterWithData()
        importer.categoryColumns = ["category", "project", "task", "subtask"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        XCTAssertNoThrow(try importer.setDateTimeParseRules(
            startUnixColumn: "unix_start",
            endUnixColumn: "unix_end",
            timezoneAbbreviation: "CST",
            testFormat: "MMM d, y @ h:mm a zzz"
        ))

        XCTAssertNoThrow(try importer.parseAll())
        
        XCTAssertEqual(importer.rows, 138)
        XCTAssertEqual(importer.events, 0)
        XCTAssertEqual(importer.ranges, 138)
        XCTAssertEqual(importer.entries, 138)
    }
    
    func test_parseAllDataToNetworkLayer() {
        self.continueAfterFailure = false

        // Setup
        let importer = self.getImporterWithData()
        importer.categoryColumns = ["category", "project", "task", "subtask"]
        XCTAssertNoThrow(try importer.buildCategoryTree())
        XCTAssertNoThrow(try importer.setDateTimeParseRules(
            startUnixColumn: "unix_start",
            endUnixColumn: "unix_end",
            timezoneAbbreviation: "CST",
            testFormat: "MMM d, y @ h:mm a zzz"
        ))
        XCTAssertNoThrow(try importer.parseAll())
        
        // Network Layer
        let decoder = JSONDecoder()
        guard let jsonData = importer.asJson(),
            let pureData = try? JSONSerialization.data(withJSONObject: jsonData, options: []),
            let decodedData = try? decoder.decode([ImporterData].self, from: pureData) else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(decodedData.count, 3)
    }
}

class Test_FileImporter_Tree: Test_FileImporterShared {
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
                
        // Root
        XCTAssertEqual(self.tree.children.count, 2)
        let cars = getChild(tree: self.tree, name: "Cars")
        testTree(tree: cars, isNil: false, name: "Cars", numChildren: 2)
        
        let planes = getChild(tree: self.tree, name: "Planes")
        testTree(tree: planes, isNil: false, name: "Planes", numChildren: 2)
        
        // Second
        let toyota = getChild(tree: cars, name: "Toyota")
        let ford = getChild(tree: cars, name: "Ford")
        let dodge = getChild(tree: cars, name: "Dodge")
        testTree(tree: toyota, isNil: false, name: "Toyota", numChildren: 2)
        testTree(tree: ford, isNil: false, name: "Ford", numChildren: 0)
        testTree(tree: dodge, isNil: true, name: "Dodge", numChildren: 0)
        
        let boeing = getChild(tree: planes, name: "Boeing")
        let airbus = getChild(tree: planes, name: "Airbus")
        testTree(tree: boeing, isNil: false, name: "Boeing", numChildren: 0)
        testTree(tree: airbus, isNil: false, name: "Airbus", numChildren: 0)
        
        // Third
        let ram = getChild(tree: toyota, name: "Ram")
        let corolla = getChild(tree: toyota, name: "Corolla")
        testTree(tree: ram, isNil: false, name: "Ram", numChildren: 0)
        testTree(tree: corolla, isNil: false, name: "Corolla", numChildren: 0)
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
    
    func test_04_asJson() {
        self.continueAfterFailure = false
        guard self.tree != nil else { XCTFail(); return }
        
        let jsonData = self.tree.asJsonDictionary(with: "CST")
        
        let decoder = JSONDecoder()
        guard let pureData = try? JSONSerialization.data(withJSONObject: jsonData, options: []),
            let decodedData = try? decoder.decode(ImporterData.self, from: pureData) else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(decodedData.name, "Test")
        XCTAssertEqual(decodedData.children.count, 2)
    }
    
    func test_05_clearStructure() {
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
