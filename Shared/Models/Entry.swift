//
//  Entry.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class Entry: Codable {
    public var id: Int
    public var type: EntryType
    public var categoryID: Int
    public var startedAt: Date
    public var endedAt: Date?
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case type
        case categoryID = "category_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
    }
    
    public init(id: Int, type: EntryType, categoryID: Int, startedAt: Date, endedAt: Date?) {
        self.id = id
        self.type = type
        self.categoryID = categoryID
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id: Int = try container.decode(Int.self, forKey: .id)
        let type: EntryType = try container.decode(EntryType.self, forKey: .type)
        let categoryID: Int = try container.decode(Int.self, forKey: .categoryID)
        let startedAtString: String = try container.decode(String.self, forKey: .startedAt)
        guard let startedAt: Date = DateHelper.dateFrom(isoString: startedAtString) else {
            throw TimeError.unableToDecodeResponse
        }
        
        let endedAtString: String? = try? container.decode(String.self, forKey: .endedAt)
        let endedAt: Date? = endedAtString != nil ? DateHelper.dateFrom(isoString: endedAtString!) : nil

        self.init(id: id, type: type, categoryID: categoryID, startedAt: startedAt, endedAt: endedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(self.id, forKey: .id)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.categoryID, forKey: .categoryID)
        
        let startedAtString: String = DateHelper.isoStringFrom(date: self.startedAt)
        try container.encodeIfPresent(startedAtString, forKey: .startedAt)
        
        let endedAtString: String? = self.endedAt != nil ? DateHelper.isoStringFrom(date: self.endedAt!) : nil
        try container.encodeIfPresent(endedAtString, forKey: .endedAt)
    }
}
