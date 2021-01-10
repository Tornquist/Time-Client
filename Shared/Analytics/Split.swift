//
//  Split.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

struct Split {
    var key: String
    var duration: TimeInterval
    var categoryID: Int
    var entryID: Int
    var open: Bool
    
    init(key: String, duration: TimeInterval, categoryID: Int, entryID: Int, open: Bool) {
        self.key = key
        self.duration = duration
        self.categoryID = categoryID
        self.entryID = entryID
        self.open = open
    }
    
    init(for entry: Entry, withKey key: String, duration: TimeInterval, open: Bool) {
        self.init(key: key, duration: duration, categoryID: entry.categoryID, entryID: entry.id, open: open)
    }
    
    init(from base: Split, key: String? = nil, duration: TimeInterval? = nil, categoryID: Int? = nil, entryID: Int? = nil, open: Bool? = nil) {
        self.init(
            key: key ?? base.key,
            duration: duration ?? base.duration,
            categoryID: categoryID ?? base.categoryID,
            entryID: entryID ?? base.entryID,
            open: open ?? base.open
        )
    }
}
