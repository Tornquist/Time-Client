//
//  Category.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public class Category: Codable {
    public var id: Int
    var parentID: Int?
    var accountID: Int
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
}
