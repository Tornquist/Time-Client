//
//  Entry.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class Entry: ObservableObject, Codable, Identifiable {
    @Published public var id: Int
    @Published public var type: EntryType
    @Published public var categoryID: Int
    @Published public var startedAt: Date
    @Published public var startedAtTimezone: String?
    @Published public var endedAt: Date?
    @Published public var endedAtTimezone: String?
    internal var deleted: Bool?
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case type
        case categoryID = "category_id"
        case startedAt = "started_at"
        case startedAtTimezone = "started_at_timezone"
        case endedAt = "ended_at"
        case endedAtTimezone = "ended_at_timezone"
        case deleted = "deleted"
    }
    
    public init(id: Int, type: EntryType, categoryID: Int, startedAt: Date, startedAtTimezone: String? = nil, endedAt: Date?, endedAtTimezone: String? = nil) {
        self.id = id
        self.type = type
        self.categoryID = categoryID
        self.startedAt = startedAt
        self.startedAtTimezone = startedAtTimezone
        self.endedAt = endedAt
        self.endedAtTimezone = endedAtTimezone
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
        let startedAtTimezone: String? = try? container.decode(String.self, forKey: .startedAtTimezone)
        
        let endedAtString: String? = try? container.decode(String.self, forKey: .endedAt)
        let endedAt: Date? = endedAtString != nil ? DateHelper.dateFrom(isoString: endedAtString!) : nil
        let endedAtTimezone: String? = try? container.decode(String.self, forKey: .endedAtTimezone)

        self.init(id: id, type: type, categoryID: categoryID, startedAt: startedAt, startedAtTimezone: startedAtTimezone, endedAt: endedAt, endedAtTimezone: endedAtTimezone)
        
        // Only path to set
        if let deleted = try? container.decode(Bool.self, forKey: .deleted) {
            self.deleted = deleted
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(self.id, forKey: .id)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.categoryID, forKey: .categoryID)
        
        let startedAtString: String = DateHelper.isoStringFrom(date: self.startedAt)
        try container.encodeIfPresent(startedAtString, forKey: .startedAt)
        try container.encodeIfPresent(self.startedAtTimezone, forKey: .startedAtTimezone)
        
        let endedAtString: String? = self.endedAt != nil ? DateHelper.isoStringFrom(date: self.endedAt!) : nil
        try container.encodeIfPresent(endedAtString, forKey: .endedAt)
        try container.encodeIfPresent(self.endedAtTimezone, forKey: .endedAtTimezone)
    }
}
