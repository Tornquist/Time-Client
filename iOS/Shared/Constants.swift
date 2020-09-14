//
//  Constants.swift
//  iOS
//
//  Created by Nathan Tornquist on 8/2/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import Foundation

struct Constants {
    private static var _groupId: String? = nil
    
    static var groupId: String {
        guard Constants._groupId == nil else { return Constants._groupId! }
        guard let fetchedPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as? String else {
            return "99AECXNBFU"
        }
        let cleanedPrefix = fetchedPrefix.trimmingCharacters(in: .punctuationCharacters)

        Constants._groupId = cleanedPrefix
        return cleanedPrefix
    }
    
    static let containerUrl = "group.com.nathantornquist.time"
    static let userDefaultsSuite = "group.com.nathantornquist.time"
    static var keychainGroup = "\(Constants.groupId).com.nathantornquist.Time"
    static let urlOverrideKey = "server_url_override"
}
