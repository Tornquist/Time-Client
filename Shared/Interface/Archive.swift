//
//  Archive.swift
//  Shared
//
//  Created by Nathan Tornquist on 9/19/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class Archive {

    enum ArchiveType {
        case accountIDs
        case categories
        case entries
        
        var filename: String {
            switch self {
            case .accountIDs:
                return "account_ids.time"
            case .categories:
                return "categories.time"
            case .entries:
                return "entries.time"
            }
        }
        
        static func identifyType<T>(for dataType: T.Type) -> ArchiveType? where T : Codable {
            if dataType == [Int].self {
                return .accountIDs
            } else if dataType == [Category].self {
                return .categories
            } else if dataType == [Entry].self {
                return .entries
            } else {
                return nil
            }
        }
        
        static func all() -> [ArchiveType] {
            return [.accountIDs, .categories, .entries]
        }
    }
        
    private static var url: URL? {
        guard let containerUrl = Globals.containerUrlOverride else {
            print("Using default")
            return try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        
        print("Using group")
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: containerUrl)
    }
    
    static func record<T>(_ data: T) -> Bool where T : Codable {
        guard
            let type = ArchiveType.identifyType(for: T.self),
            let encodedData = try? JSONEncoder().encode(data),
            let url = Archive.url else {
                return false
        }
        
        let fullPath = url.appendingPathComponent(type.filename)
        do {
            try encodedData.write(to: fullPath)
            return true
        } catch {
            return false
        }
    }
    
    static func retrieveData<T>() -> T? where T : Codable {
        print("retrieveData")
        guard
            let type = ArchiveType.identifyType(for: T.self),
            let url = Archive.url,
            let data = try? Data.init(contentsOf:
                url.appendingPathComponent(type.filename)
            ),
            let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        
        return decodedData
    }
    
    static func removeData(for type: ArchiveType) -> Bool {
        guard let url = Archive.url else {
            return false
        }
        
        let fullPath = url.appendingPathComponent(type.filename)
        let fileExists = FileManager.default.fileExists(atPath: fullPath.path)
        guard fileExists else { return true }
        
        do {
            try FileManager.default.removeItem(at: fullPath)
            return true
        } catch {
            return false
        }
    }
    
    static func removeAllData() -> Bool {
        return ArchiveType.all()
            .map({ Archive.removeData(for: $0) })
            .reduce(true, { $0 && $1 })
    }
}
