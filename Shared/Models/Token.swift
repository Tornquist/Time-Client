//
//  Token.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

struct Token: Codable {
    var userID: Int
    var creation: Date
    var expiration: Date
    var token: String
    var refresh: String
    
    enum CodingKeys: String, CodingKey
    {
        case userID = "user_id"
        case creation
        case expiration
        case token
        case refresh
    }
}
