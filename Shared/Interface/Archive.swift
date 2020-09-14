//
//  Archive.swift
//  Shared
//
//  Created by Nathan Tornquist on 9/19/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class Archive {
    
    var containerURL: String?
    
    init(containerURL: String? = nil) {
        self.containerURL = containerURL
    }
    convenience init(config: TimeConfig) {
        self.init(containerURL: config.containerURL)
    }

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
        
    private var url: URL? {
        guard let containerUrl = self.containerURL else {
            return try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: containerUrl)
    }
    
    func record<T>(_ data: T) -> Bool where T : Codable {
        guard
            let type = ArchiveType.identifyType(for: T.self),
            let encodedData = try? JSONEncoder().encode(data),
            let url = self.url else {
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
    
    func retrieveData<T>() -> T? where T : Codable {
        guard
            let type = ArchiveType.identifyType(for: T.self),
            let url = self.url,
            let data = try? Data.init(contentsOf:
                url.appendingPathComponent(type.filename)
            ),
            let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        
        return decodedData
    }
    
    func removeData(for type: ArchiveType) -> Bool {
        guard let url = self.url else {
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
    
    func removeAllData() -> Bool {
        return ArchiveType.all()
            .map({ self.removeData(for: $0) })
            .reduce(true, { $0 && $1 })
    }
}
