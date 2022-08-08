//
//  TimePeriod.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/9/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

public enum TimePeriod: String, Identifiable {
    case year
    case month
    case week
    case day
    
    public var display: String { self.rawValue.capitalized }
    
    public var id: Int { hashValue }
    static public func all() -> [TimePeriod] {
        return [.day, .week, .month, .year]
    }
}

public struct TimeRange {
    var period: TimePeriod
    var isRolling: Bool
    var isCurrent: Bool {
        return !self.isRolling
    }
    
    public init(rolling period: TimePeriod) {
        self.period = period
        self.isRolling = true
    }
    
    public init(current period: TimePeriod) {
        self.period = period
        self.isRolling = false
    }
}
