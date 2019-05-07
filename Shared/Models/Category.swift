//
//  Category.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class Category: Codable, Equatable {
    public var id: Int
    public var parentID: Int?
    public var accountID: Int
    public var name: String
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case parentID = "parent_id"
        case accountID = "account_id"
        case name
    }
    
    init(id: Int, parentID: Int?, accountID: Int, name: String) {
        self.id = id
        self.parentID = parentID
        self.accountID = accountID
        self.name = name
    }
    
    public static func ==(lhs: Category, rhs: Category) -> Bool {
        // Name is not included. Equality is based on structure
        // alone, not display values.
        return lhs.id == rhs.id
            && lhs.parentID == rhs.parentID
            && lhs.accountID == rhs.accountID
    }
}
