//
//  FileImporter.swift
//  Shared
//
//  Created by Nathan Tornquist on 11/10/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public enum FileImporterError: Error {
    case fileNotFound
    case unableToReadFile
    case unableToParseCSV
    case categoryColumnsNotSpecified
    case missingObjectData
    case invalidTimeDateCombination
    case setupNotCompleted
}

public class FileImporter {
    // Init
    let fileURL: URL
    let separator: Character
    
    // External
    public var categoryColumns: [String] = []
    public var rows: Int? {
        return rawObjects?.count
    }
    public var events: Int? {
        return self.categoryTree?.count(events: true)
    }
    public var ranges: Int? {
        return self.categoryTree?.count(ranges: true)
    }
    public var entries: Int? {
        return self.categoryTree?.count(events: true, ranges: true)
    }
    
    // Internal
    var _columns: [String]? = nil
    public var columns: [String]? {
        return self._columns
    }
    var rawObjects: [[String: String?]]? = nil
    var parsedObjectTrees: [[String]]? = nil
    var categoryTree: Tree? = nil
    
    var dateColumn: String? = nil
    var startTimeColumn: String? = nil
    var endTimeColumn: String? = nil
    var dateFormat: String? = nil
    var timeFormat: String? = nil
    var startUnixColumn: String? = nil
    var endUnixColumn: String? = nil
    var timeZone: TimeZone? = nil
    
    private struct DatePair {
        var start: Date?
        var end: Date?
        
        var rawStartDate: String?
        var rawEndDate: String?
    }
    
    public init(fileURL: URL, separator: Character = ",") {
        self.fileURL = fileURL
        self.separator = separator
    }
    
    public func loadData() throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: self.fileURL.path) else {
            throw FileImporterError.fileNotFound
        }
        
        guard let fileContents = try? String(contentsOf: fileURL) else {
            throw FileImporterError.unableToReadFile
        }

        let rawRows = fileContents.components(separatedBy: .newlines)
        guard rawRows.count >= 2 else {
            throw FileImporterError.unableToParseCSV
        }

        let headerRow = rawRows[0]
        let dataRows = rawRows[1...].map({ String($0) })

        let columns = headerRow.split(separator: separator).map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard columns.count > 1 else {
            throw FileImporterError.unableToParseCSV
        }
        self._columns = columns

        self.rawObjects = try dataRows.map({ (row) -> [String: String?] in
            let rowData = row.split(separator: ",", omittingEmptySubsequences: false)
            guard rowData.count == columns.count else {
                throw FileImporterError.unableToParseCSV
            }
            
            let rowPairs = zip(columns, rowData)
            var formattedData: [String: String?] = [:]
            
            rowPairs.forEach({ (entry) in
                let column = entry.0
                let value = String(entry.1).trimmingCharacters(in: .whitespacesAndNewlines)
                let safeValue = value.count > 0 && value != "\"\"" ? value : nil
                formattedData[column] = safeValue
            })
            
            return formattedData
        })
    }
    
    public func buildCategoryTree() throws {
        guard self.categoryColumns.count > 0 else {
            throw FileImporterError.categoryColumnsNotSpecified
        }
        
        let objectTrees = self.rawObjects!.map { (entry) -> [String] in
            let entryTree: [String?] = categoryColumns.map { (column) -> String? in
                return entry[column] ?? nil
            }
            let nilIndex = entryTree.firstIndex(where: { (value) -> Bool in
                return value == nil
            }) ?? entryTree.endIndex
            let trueTree = entryTree[0..<nilIndex].compactMap({ $0 })
            return trueTree
        }
        self.parsedObjectTrees = objectTrees
        let safeObjectTrees = Array(Set(objectTrees))
        
        let completeTree = Tree(name: "")
        safeObjectTrees.forEach { (tree) in
            completeTree.buildDescendents(with: tree)
        }
        
        self.categoryTree = completeTree
    }
    
    public func setDateTimeParseRules(
        dateColumn: String,
        startTimeColumn: String,
        endTimeColumn: String,
        dateFormat: String,
        timeFormat: String,
        timezoneAbbreviation: String? = nil,
        timezoneIdentifier: String? = nil,
        testFormat: String = "MMM d, y @ h:mm a zzz"
    ) throws -> (startRaw: String?, startParsed: String?, endRaw: String?, endParsed: String?) {
        return try self.setDateTimeParseRules(
            dateColumn: dateColumn,
            startTimeColumn: startTimeColumn,
            endTimeColumn: endTimeColumn,
            dateFormat: dateFormat,
            timeFormat: timeFormat,
            startUnixColumn: nil,
            endUnixColumn: nil,
            timezoneAbbreviation: timezoneAbbreviation,
            timezoneIdentifier: timezoneIdentifier,
            testFormat: testFormat
        )
    }
    
    public func setDateTimeParseRules(
        startUnixColumn: String,
        endUnixColumn: String,
        timezoneAbbreviation: String? = nil,
        timezoneIdentifier: String? = nil,
        testFormat: String = "MMM d, y @ h:mm a zzz"
    ) throws -> (startRaw: String?, startParsed: String?, endRaw: String?, endParsed: String?) {
        return try self.setDateTimeParseRules(
            dateColumn: nil,
            startTimeColumn: nil,
            endTimeColumn: nil,
            dateFormat: nil,
            timeFormat: nil,
            startUnixColumn: startUnixColumn,
            endUnixColumn: endUnixColumn,
            timezoneAbbreviation: timezoneAbbreviation,
            timezoneIdentifier: timezoneIdentifier,
            testFormat: testFormat
        )
    }
    
    private func setDateTimeParseRules(
        dateColumn: String? = nil,
        startTimeColumn: String? = nil,
        endTimeColumn: String? = nil,
        dateFormat: String? = nil,
        timeFormat: String? = nil,
        startUnixColumn: String? = nil,
        endUnixColumn: String? = nil,
        timezoneAbbreviation: String? = nil,
        timezoneIdentifier: String? = nil,
        testFormat: String = "MMM d, y @ h:mm a zzz"
    ) throws -> (startRaw: String?, startParsed: String?, endRaw: String?, endParsed: String?) {
        let noDateAndTime = dateColumn == nil &&
            startTimeColumn == nil &&
            endTimeColumn == nil &&
            dateFormat == nil &&
            timeFormat == nil
        let allDateAndTime = dateColumn != nil &&
            startTimeColumn != nil &&
            endTimeColumn != nil &&
            dateFormat != nil &&
            timeFormat != nil
        
        let noUnix = startUnixColumn == nil && endUnixColumn == nil
        let allUnix = startUnixColumn != nil && endUnixColumn != nil
        let mismatchedTimezone = timezoneAbbreviation != nil && timezoneIdentifier != nil
        
        guard ((noDateAndTime && allUnix) || (allDateAndTime && noUnix)) && !mismatchedTimezone else {
            throw FileImporterError.invalidTimeDateCombination
        }
        
        guard self.rawObjects != nil && self.rawObjects!.count > 0, let testObj = self.rawObjects?[0] else {
            throw FileImporterError.missingObjectData
        }
        
        let timeZoneFromAbbreviation = (timezoneAbbreviation != nil ? TimeZone(abbreviation: timezoneAbbreviation!) : nil)
        let timeZoneFromIdentifier = (timezoneIdentifier != nil ? TimeZone(identifier: timezoneIdentifier!) : nil)
        let timeZone = timeZoneFromAbbreviation ?? timeZoneFromIdentifier ?? TimeZone.autoupdatingCurrent
        
        self.dateColumn = dateColumn
        self.startTimeColumn = startTimeColumn
        self.endTimeColumn = endTimeColumn
        self.dateFormat = dateFormat
        self.timeFormat = timeFormat
        self.startUnixColumn = startUnixColumn
        self.endUnixColumn = endUnixColumn
        self.timeZone = timeZone

        let testResults = self.parse(obj: testObj)
        
        let testFormatter = DateFormatter()
        testFormatter.timeZone = timeZone
        testFormatter.dateFormat = testFormat
        
        let startParsedString = testResults.start != nil ? testFormatter.string(from: testResults.start!) : nil
        let endParsedString = testResults.end != nil ? testFormatter.string(from: testResults.end!) : nil
        
        return (testResults.rawStartDate, startParsedString, testResults.rawEndDate, endParsedString)
    }
    
    public func parseAll() throws {
        let setDateTime = self.startTimeColumn != nil || self.startUnixColumn != nil
        let parsedCategories = self.categoryTree != nil && self.parsedObjectTrees != nil
        guard setDateTime && parsedCategories && self.rawObjects != nil else {
            throw FileImporterError.setupNotCompleted
        }
        
        // Clean previously stored events
        self.categoryTree?.cleanStructure()
        
        self.rawObjects!.enumerated().forEach { (index, obj) in
            let parsedDates = self.parse(obj: obj)
            guard parsedDates.start != nil else {
                return
            }
            
            let categories = self.parsedObjectTrees![index]
            self.categoryTree?.store(start: parsedDates.start!, andEnd: parsedDates.end, with: categories)
        }
    }
    
    private func parse(obj: [String : String?]) -> DatePair {
        let unix = self.startUnixColumn != nil
        
        var startDate: Date?
        var startRaw: String?
        var endDate: Date?
        var endRaw: String?
        
        if (unix) {
            if let startString = obj[self.startUnixColumn!] ?? nil, let startInt = Int(startString) {
                startRaw = startString
                startDate = Date(timeIntervalSince1970: Double(startInt))
            }
            
            if let endString = obj[self.endUnixColumn!] ?? nil, let endInt = Int(endString) {
                endRaw = endString
                endDate = Date(timeIntervalSince1970: Double(endInt))
            }
        } else {
            let dateparser = DateFormatter()
            dateparser.timeZone = self.timeZone
            
            if let dateString = obj[self.dateColumn!] ?? nil, let startString = obj[self.startTimeColumn!] ?? nil {
                let startFormat = "\(dateFormat!) \(timeFormat!)"
                let startCompiledString = "\(dateString) \(startString)"
                
                startRaw = startCompiledString
                
                dateparser.dateFormat = startFormat
                startDate = dateparser.date(from: startCompiledString)
            }
            
            if let dateString = obj[self.dateColumn!] ?? nil, let endString = obj[self.endTimeColumn!] ?? nil {
                let endFormat = "\(dateFormat!) \(timeFormat!)"
                let endCompiledString = "\(dateString) \(endString)"
                
                endRaw = endCompiledString
                
                dateparser.dateFormat = endFormat
                endDate = dateparser.date(from: endCompiledString)
            }
        }
        
        return DatePair(start: startDate, end: endDate, rawStartDate: startRaw, rawEndDate: endRaw)
    }
    
    public func asJson() -> [[String: Any]]? {
        guard self.categoryTree != nil else { return nil }

        let timeZoneString = self.timeZone?.identifier
        let rootTrees: [[String: Any]] = self.categoryTree!.children.compactMap({ (tree) -> [String: Any] in
            return tree.asJsonDictionary(with: timeZoneString)
        })
        return rootTrees
    }
}

extension FileImporter {
    internal class Tree {
        let name: String
        var children: [Tree] = []
        
        var events: [Date] = []
        var ranges: [(Date, Date)] = []
        
        init(name: String) {
            self.name = name
        }
        
        func buildDescendents(with names: [String]) {
            guard names.count > 0 else { return }
            
            let childName = names[0]
            let descendentNames = names[1...].map({ String($0) })
            
            let child = self.getChild(withName: childName) ?? self.addChild(withName: childName)
            child.buildDescendents(with: descendentNames)
        }
            
        private func getChild(withName name: String) -> Tree? {
            return children.first(where: { (child) -> Bool in
                return child.name == name
            })
        }
        
        private func addChild(withName name: String) -> Tree {
            let newChild = Tree(name: name)
            self.children.append(newChild)
            return newChild
        }
        
        func store(start: Date, andEnd end: Date?, with names: [String]) {
            guard names.count > 0 else {
                if end == nil {
                    self.events.append(start)
                } else {
                    self.ranges.append((start, end!))
                }
                return
            }
            
            let childName = names[0]
            let descendentNames = names[1...].map({ String($0) })
            guard let child = self.getChild(withName: childName) else {
                // Should not be possible
                return
            }
            
            child.store(start: start, andEnd: end, with: descendentNames)
        }
        
        func count(events: Bool = false, ranges: Bool = false) -> Int {
            let childrenCount = self.children.map({
                $0.count(events: events, ranges: ranges)
            }).reduce(0, { $0 + $1 })
            
            let eventCount = events ? self.events.count : 0
            let rangeCount = ranges ? self.ranges.count : 0
            
            return childrenCount + eventCount + rangeCount
        }
        
        func cleanStructure() {
            self.events = []
            self.ranges = []
            self.children.forEach({ $0.cleanStructure() })
        }
        
        func asJsonDictionary(with timezone: String? = nil) -> [String: Any] {
            return [
                "name": self.name,
                "events": self.events.map({ (event) -> [String:String] in
                    var baseData = [
                        "started_at": DateHelper.isoStringFrom(date: event, includeMilliseconds: true)
                    ]
                    if timezone != nil {
                        baseData["started_at_timezone"] = timezone!
                    }
                    return baseData
                }),
                "ranges": self.ranges.map({ (event) -> [String:String] in
                    var baseData = [
                        "started_at": DateHelper.isoStringFrom(date: event.0, includeMilliseconds: true),
                        "ended_at": DateHelper.isoStringFrom(date: event.1, includeMilliseconds: true)
                    ]
                    if timezone != nil {
                        baseData["started_at_timezone"] = timezone!
                        baseData["ended_at_timezone"] = timezone!
                    }
                    return baseData
                }),
                "children": self.children.map({ $0.asJsonDictionary(with: timezone) })
            ]
        }
    }
}

extension FileImporter {
    public class Request: Decodable {
        public var id: Int
        public var createdAt: Date
        public var updatedAt: Date
        public var categories: Request.Status
        public var entries: Request.Status
        public var complete: Bool
        public var success: Bool
                
        public struct Status: Codable {
            var imported: Int
            var expected: Int
        }
        
        enum CodingKeys: String, CodingKey
        {
            case id
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case categories
            case entries
            case complete
            case success
        }
        
        public init(id: Int, createdAt: Date, updatedAt: Date, categories: Request.Status, entries: Request.Status, complete: Bool, success: Bool) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.categories = categories
            self.entries = entries
            self.complete = complete
            self.success = success
        }
        
        public required convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let id: Int = try container.decode(Int.self, forKey: .id)
            let createdAtString: String = try container.decode(String.self, forKey: .createdAt)
            guard let createdAt: Date = DateHelper.dateFrom(isoString: createdAtString) else {
                throw TimeError.unableToDecodeResponse
            }
            let updatedAtString: String = try container.decode(String.self, forKey: .updatedAt)
            guard let updatedAt: Date = DateHelper.dateFrom(isoString: updatedAtString) else {
                throw TimeError.unableToDecodeResponse
            }
            let categories: Request.Status = try container.decode(Request.Status.self, forKey: .categories)
            let entries: Request.Status = try container.decode(Request.Status.self, forKey: .entries)
            let complete: Bool = try container.decode(Bool.self, forKey: .complete)
            let success: Bool = try container.decode(Bool.self, forKey: .success)
            
            self.init(id: id, createdAt: createdAt, updatedAt: updatedAt, categories: categories, entries: entries, complete: complete, success: success)
        }
    }
}
