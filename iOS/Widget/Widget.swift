//
//  Widget.swift
//  Widget
//
//  Created by Nathan Tornquist on 7/25/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import TimeSDK

struct Theme {
    // System Colors
    static var label: Color {
        return Color(UIColor.label)
    }
    static var background: Color {
        return Color(UIColor.secondarySystemGroupedBackground)
    }
    
    // Internal Colors
    static var active: Color {
        return Color(Colors.active)
    }
    
    static var button: Color {
        return Color(Colors.button)
    }
}

@main
struct SummaryWidget: Widget {
    private let kind: String = "com.nathantornquist.time.SummaryWidget"
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTimeline()) { entry in
            TimeWidgetView(entry: entry)
        }
        .configurationDisplayName("Summary")
        .description("Shows a summary of the elapsed time for the day and week.")
        .supportedFamilies([.systemSmall])
    }
}

struct TimeLoader {
    static func fetch(completion: @escaping (Result<TimeStatus, Error>) -> Void) {
        var dayQuantity: TimeQuantity? = nil
        var weekQuantity: TimeQuantity? = nil
        var isActive = false
        
        let now = Date()
        let calendar = Calendar.current
        
        let dayComps = calendar.dateComponents([.day, .month, .year], from: now)
        let weekComps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)
        
        let startOfDay = calendar.date(from: dayComps)!
        let startOfWeek = calendar.date(from: weekComps)!
        
        let doneWithRange = {
            guard dayQuantity != nil && weekQuantity != nil else { return }
            
            let status = TimeStatus(today: dayQuantity!, week: weekQuantity!, active: isActive)
            completion(.success(status))
        }
        
        let sharedUserDefaults = UserDefaults(suiteName: Constants.userDefaultsSuite)
        let serverURLOverride = sharedUserDefaults?.string(forKey: Constants.urlOverrideKey)
                
        let config = TimeConfig(
            serverURL: serverURLOverride,
            containerURL: Constants.containerUrl,
            userDefaultsSuite: Constants.userDefaultsSuite,
            keychainGroup: Constants.keychainGroup
        )
        
        Time.configureShared(config)
        Time.shared.initialize() { error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            // Check day total
            self.getFrom(date: startOfDay) { (day, active) in
                dayQuantity = day
                isActive = isActive || active

                doneWithRange()
            }
            // Check week total
            self.getFrom(date: startOfWeek) { (week, active) in
                weekQuantity = week
                isActive = isActive || active

                doneWithRange()
            }
        }
    }
    
    static internal func getFrom(date: Date, completion: @escaping (TimeQuantity?, Bool) -> ()) {
        Time.shared.store.getEntries(after: date) { (entries: [Entry]?, error: Error?) -> () in
            guard entries != nil && error == nil else {
                completion(TimeQuantity.unknown, false)
                return
            }
            
            var isActive = false
            let totalTime = entries!.compactMap({ (entry) -> TimeInterval? in
                guard entry.type == .range else { return nil }
                
                guard entry.endedAt != nil else {
                    isActive = true
                    return Date().timeIntervalSince(entry.startedAt)
                }
                
                return entry.endedAt!.timeIntervalSince(entry.startedAt)
            }).reduce(0) { $0 + $1 }
            
            let getTimeQuantity = { (time: Int) -> TimeQuantity in
                let seconds = (time % 60)
                let minutes = (time / 60) % 60
                let hours = (time / 3600)
                
                return TimeQuantity(hours: hours, minutes: minutes, seconds: seconds)
            }
            
            completion(getTimeQuantity(Int(totalTime)), isActive)
        }
    }
}

struct TimeQuantity {
    let hours: Int
    let minutes: Int
    let seconds: Int
    
    var frozenDisplayValue: String {
        guard !self.isUnknown else { return "XX:XX:XX" }
        
        let showSeconds = true
        let timeString = showSeconds // TODO: Use app settings
            ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", hours, minutes)
        return timeString
    }
    
    var activeRelativeDate: Date {
        let components = DateComponents(hour: -self.hours, minute: -self.minutes, second: -self.seconds)
        let pastDate = Calendar.current.date(byAdding: components, to: Date())!
        return pastDate
    }
    
    var activePrefix: String {
        if hours >= 10 {
            return ""
        } else if hours >= 1 {
            return "0"
        } else if minutes >= 10 {
            return "00:"
        } else {
            return "00:0"
        }
    }
    
    var isUnknown: Bool {
        return self.hours == -1
    }
    
    static var unknown: TimeQuantity {
        return TimeQuantity(hours: -1, minutes: -1, seconds: -1)
    }
}

struct TimeStatus {
    let today: TimeQuantity
    let week: TimeQuantity
    let active: Bool
}

struct TimeEntry: TimelineEntry {
    public let date: Date
    public let status: TimeStatus
}

struct TimeTimeline: TimelineProvider {
    typealias Entry = TimeEntry
    
    public func placeholder(in context: Context) -> TimeEntry {
        let today = TimeQuantity(hours: 1, minutes: 38, seconds: 04)
        let week = TimeQuantity(hours: 53, minutes: 43, seconds: 59)
        let fakeStatus = TimeStatus(today: today, week: week, active: true)
        let entry = TimeEntry(date: Date(), status: fakeStatus)
        return entry
    }
    
    // Fake information for previews
    public func getSnapshot(in context: Context, completion: @escaping (TimeEntry) -> Void) {
        let today = TimeQuantity(hours: 1, minutes: 38, seconds: 04)
        let week = TimeQuantity(hours: 53, minutes: 43, seconds: 59)
        let fakeStatus = TimeStatus(today: today, week: week, active: true)
        let entry = TimeEntry(date: Date(), status: fakeStatus)
        completion(entry)
    }
    
    // Real information
    public func getTimeline(in context: Context, completion: @escaping (Timeline<TimeEntry>) -> Void) {
        let currentDate = Date()
        let earlyDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let farDate = Calendar.current.date(byAdding: .minute, value: 120, to: currentDate)!
        
        TimeLoader.fetch { (result) in
            let status: TimeStatus
            if case .success(let fetchedStatus) = result {
                status = fetchedStatus
            } else {
                let zeroDay = TimeQuantity(hours: 0, minutes: 0, seconds: 0)
                status = TimeStatus(today: zeroDay, week: zeroDay, active: false)
            }
            let entry = TimeEntry(date: currentDate, status: status)
            let timeline = Timeline(entries: [entry], policy: .after(status.active ? earlyDate : farDate))
            completion(timeline)
        }
    }
}

struct TimeWidgetView : View {
    let entry: TimeEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            getBlock("Today", value: entry.status.today, active: entry.status.active)
            Spacer()
            getBlock("This Week", value: entry.status.week, active: entry.status.active)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Theme.background)
    }
    
    func getBlock(_ title: String, value: TimeQuantity, active: Bool) -> some View {
        return VStack(alignment: .leading, spacing: 4, content: {
            (
                active
                    ? (Text(value.activePrefix) + Text(value.activeRelativeDate, style: .timer))
                    : Text(value.frozenDisplayValue)
            )
                .font(Font.system(size: 24.0, weight: .regular, design: .default).monospacedDigit())
                .foregroundColor(active ? Theme.active : Theme.label)
            Text(title)
                .font(Font.system(size: 10.0, weight: .regular, design: .default))
                .foregroundColor(Theme.label)
        })
    }
}

struct TimeWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TimeWidgetView(entry: TimeEntry(
            date: Date(),
            status: TimeStatus(
                today: TimeQuantity(hours: 0, minutes: 6, seconds: 36),
                week: TimeQuantity(hours: 11, minutes: 22, seconds: 33),
                active: true
            )
        )).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
