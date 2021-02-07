//
//  Category.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation
import Combine

public class Category: ObservableObject, Codable, Equatable, Identifiable {
    @Published public var id: Int
    @Published public var parentID: Int?
    @Published public var accountID: Int
    @Published public var name: String
    
    @Published private var _expanded: Bool = false
    internal var expanded: Bool {
        get { return self._expanded }
        set {
            guard self._expanded != newValue else { return }
            
            self._expanded = newValue
            NotificationCenter.default.post(name: .TimeCategoryArchiveRequested, object: self)
        }
    }
    
    enum CodingKeys: String, CodingKey
    {
        /* API Fields */
        case id
        case parentID = "parent_id"
        case accountID = "account_id"
        case name

        /* Internal */
        case _expanded = "_expanded"
    }
    
    init(id: Int, parentID: Int?, accountID: Int, name: String) {
        self.id = id
        self.parentID = parentID
        self.accountID = accountID
        self.name = name
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try values.decode(Int.self, forKey: .id)
        self.parentID = try? values.decode(Int.self, forKey: .parentID)
        self.accountID = try values.decode(Int.self, forKey: .accountID)
        self.name = try values.decode(String.self, forKey: .name)
        
        if values.contains(._expanded) {
            // Set directly to avoid setter on init
            self._expanded = try values.decode(Bool.self, forKey: ._expanded)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(parentID, forKey: .parentID)
        try container.encode(accountID, forKey: .accountID)
        try container.encode(name, forKey: .name)
        
        // Add to internal state
        try container.encode(_expanded, forKey: ._expanded)
    }
    
    public static func ==(lhs: Category, rhs: Category) -> Bool {
        // Name is not included. Equality is based on structure
        // alone, not display values.
        return lhs.id == rhs.id
            && lhs.parentID == rhs.parentID
            && lhs.accountID == rhs.accountID
    }
}
