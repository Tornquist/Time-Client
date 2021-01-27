//
//  EntryAnalysis.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/10/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

struct EntryAnalysis {
    var source: Entry
    var splits: [Split]
    
    static func generate(for entry: Entry) -> EntryAnalysis {
        let splits = Split.identify(for: entry)
        return EntryAnalysis(source: entry, splits: splits)
    }
}
