//
//  TimePeriod.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

public enum TimePeriod {
    case year
    case month
    case week
    case day
}

public struct TimeRange {
    var period: TimePeriod
    var isRolling: Bool
    var isCurrent: Bool {
        return !self.isRolling
    }
    
    init(rolling period: TimePeriod) {
        self.period = period
        self.isRolling = true
    }
    
    init(current period: TimePeriod) {
        self.period = period
        self.isRolling = false
    }
}
