//
//  Account.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/12/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class Account: Codable {
    var id: Int
    var userIDs: [Int]
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case userIDs = "user_ids"
    }
}
