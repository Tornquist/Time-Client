//
//  DateHelper.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/24/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class DateHelper {
    
    // MARK: - Formatters
    
    private static var _isoFormatter: ISO8601DateFormatter? = nil
    private static var isoFormatter: ISO8601DateFormatter {
        if _isoFormatter == nil {
            _isoFormatter = ISO8601DateFormatter()
        }
        return _isoFormatter!
    }
    
    private static var _isoMillisecondsFormatter: ISO8601DateFormatter? = nil
    private static var isoMillisecondsFormatter: ISO8601DateFormatter {
        if _isoMillisecondsFormatter == nil {
            _isoMillisecondsFormatter = ISO8601DateFormatter()
            _isoMillisecondsFormatter!.formatOptions =  [
                .withInternetDateTime, // Flag set by default. Set here to avoid clearing
                .withFractionalSeconds
            ]
        }
        
        return _isoMillisecondsFormatter!
    }
    
    // MARK: - Helper Methods
    
    static func isoStringFrom(date: Date, includeMilliseconds: Bool = true) -> String {
        if includeMilliseconds {
            return DateHelper.isoMillisecondsFormatter.string(from: date)
        } else {
            return DateHelper.isoFormatter.string(from: date)
        }
    }
    
    static func dateFrom(isoString stringDate: String) -> Date? {
        if let date = DateHelper.isoFormatter.date(from: stringDate) {
            return date
        } else if let date = DateHelper.isoMillisecondsFormatter.date(from: stringDate) {
            return date
        }
        
        return nil
    }
}
