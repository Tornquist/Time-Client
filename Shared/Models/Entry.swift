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
    
    init(id: Int, type: EntryType, categoryID: Int, startedAt: Date, endedAt: Date?) {
        self.id = id
        self.type = type
        self.categoryID = categoryID
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
