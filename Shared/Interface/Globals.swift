//
//  Globals.swift
//  Shared
//
//  Created by Nathan Tornquist on 8/2/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import Foundation

class Globals {
    static var containerUrlOverride: String? = nil
    static var userDefaultsSuiteName: String? = nil
    
    static var userDefaults: UserDefaults {
        // Will resolve safely as long as the provided suiteName is within
        // the app's allowed access
        return UserDefaults(suiteName: Globals.userDefaultsSuiteName)!
    }
}
