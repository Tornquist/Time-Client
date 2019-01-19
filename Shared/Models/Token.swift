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
    
    init(userID: Int, creation: Date, expiration: Date, token: String, refresh: String) {
        self.userID = userID
        self.creation = creation
        self.expiration = expiration
        self.token = token
        self.refresh = refresh
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let userID: Int = try container.decode(Int.self, forKey: .userID)
        let creationMS: Double = try container.decode(Double.self, forKey: .creation)
        let creation: Date = Date.init(timeIntervalSince1970: creationMS / 1000.0)
        let expirationMS: Double = try container.decode(Double.self, forKey: .expiration)
        let expiration: Date = Date.init(timeIntervalSince1970: expirationMS / 1000.0)
        
        let token: String = try container.decode(String.self, forKey: .token)
        let refresh: String = try container.decode(String.self, forKey: .refresh)
        
        self.init(userID: userID, creation: creation, expiration: expiration, token: token, refresh: refresh)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(self.userID, forKey: .userID)
        try container.encodeIfPresent(self.token, forKey: .token)
        try container.encodeIfPresent(self.refresh, forKey: .refresh)
        
        let creationTimeSeconds: Double = self.creation.timeIntervalSince1970
        let creationTimeMilliseconds = round(creationTimeSeconds * 1000)
        try container.encodeIfPresent(creationTimeMilliseconds, forKey: .creation)
        
        let expirationTimeSeconds: Double = self.creation.timeIntervalSince1970
        let expirationTimeMilliseconds = round(expirationTimeSeconds * 1000)
        try container.encodeIfPresent(expirationTimeMilliseconds, forKey: .expiration)
    }
}
