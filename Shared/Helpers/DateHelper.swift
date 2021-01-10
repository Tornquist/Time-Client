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
    
    // MARK: - Base Helper Methods
    
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
    
    static func getSafeTimezone(identifier: String?) -> TimeZone {
        let defaultTimezone = TimeZone.autoupdatingCurrent
        let safeIdentifier = identifier ?? defaultTimezone.identifier
        let timezone = TimeZone(identifier: safeIdentifier) ?? defaultTimezone
        return timezone
    }

    // MARK: - Date Ranges
    
    static func getStartOf(_ timeRange: TimeRange, for calendar: Calendar) -> Date {
        let startToday = calendar.startOfDay(for: Date())
        
        let thisYearComponents = calendar.dateComponents([.year], from: startToday)
        let thisMonthComponent = calendar.dateComponents([.year, .month], from: startToday)
        let thisWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startToday)
        
        let rollingOneMonthComponent = DateComponents(month: -1)
        let rollingOneWeekComponent = DateComponents(day: -7) // Perhaps -6 to have 7 days (6 past + today)
        let rollingOneYearComponent = DateComponents(year: -1)
        
        let yearToDate = calendar.date(from: thisYearComponents)
        let monthToDate = calendar.date(from: thisMonthComponent) // No day --> Day = 1
        let weekToDate = calendar.date(from: thisWeekComponents)
        
        let oneYear = calendar.date(byAdding: rollingOneYearComponent, to: startToday)
        let oneMonth = calendar.date(byAdding: rollingOneMonthComponent, to: startToday)
        let oneWeek = calendar.date(byAdding: rollingOneWeekComponent, to: startToday)
        
        let searchDate = { () -> Date? in
            switch timeRange.period {
            case .day:
                return startToday
            case .week:
                return timeRange.isCurrent ? weekToDate : oneWeek
            case .month:
                return timeRange.isCurrent ? monthToDate : oneMonth
            case .year:
                return timeRange.isCurrent ? yearToDate : oneYear
            }
        }()
        return searchDate!
    }
}
