//
//  FileImporter.swift
//  Shared
//
//  Created by Nathan Tornquist on 11/10/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class Tree {
    let name: String
    var children: [Tree] = []
    
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
    
    func getChild(withName name: String) -> Tree? {
        return children.first(where: { (child) -> Bool in
            return child.name == name
        })
    }
    
    func addChild(withName name: String) -> Tree {
        let newChild = Tree(name: name)
        self.children.append(newChild)
        return newChild
    }
}

public enum FileImporterError: Error {
    case fileNotFound
    case unableToReadFile
    case unableToParseCSV
    case categoryColumnsNotSpecified
    case missingObjectData
    case invalidTimeDateCombination
}

public class FileImporter {
    // Init
    let fileURL: URL
    let separator: Character
    
    // External
    public var categoryColumns: [String] = []
    
    // Internal
    public var columns: [String]? = nil
    var rawObjects: [[String: String?]]? = nil
    var categoryTree: Tree? = nil
    
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
        self.columns = columns

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
        let safeObjectTrees = Array(Set(objectTrees))
        
        let completeTree = Tree(name: "")
        safeObjectTrees.forEach { (tree) in
            completeTree.buildDescendents(with: tree)
        }
        
        self.categoryTree = completeTree
    }
}
