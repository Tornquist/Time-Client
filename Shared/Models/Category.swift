//
//  Category.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/4/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class Category: Codable {
    var id: Int
    var parentID: Int?
    var accountID: Int
    var name: String
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case parentID = "parent_id"
        case accountID = "account_id"
        case name
    }
}
