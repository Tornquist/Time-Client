//
//  Disk.swift
//  Shared
//
//  Created by Nathan Tornquist on 9/19/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

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

class Archive {
    private static var applicationSupportFolderURL: URL? {
        return try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
    
    static func record<T>(_ data: T) where T : Codable {
        guard
            let type = ArchiveType.identifyType(for: T.self),
            let encodedData = try? JSONEncoder().encode(data),
            let url = Archive.applicationSupportFolderURL else {
                return
        }
        
        let fullPath = url.appendingPathComponent(type.filename)
        try? encodedData.write(to: fullPath)
    }
    
    static func retrieveData<T>() -> T? where T : Codable {
        guard
            let type = ArchiveType.identifyType(for: T.self),
            let url = Archive.applicationSupportFolderURL,
            let data = try? Data.init(contentsOf:
                url.appendingPathComponent(type.filename)
            ),
            let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        
        return decodedData
    }
    
    static func removeData(for type: ArchiveType) {
        guard let url = Archive.applicationSupportFolderURL else {
            return
        }
        
        let fullPath = url.appendingPathComponent(type.filename)
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    static func removeAllData() {
        ArchiveType.all().forEach { (type) in
            Archive.removeData(for: type)
        }
    }
}
