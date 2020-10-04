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
        let now = Date()
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
                    return now.timeIntervalSince(entry.startedAt)
                }
                
                return entry.endedAt!.timeIntervalSince(entry.startedAt)
            }).reduce(0) { $0 + $1 }
            
            completion(TimeQuantity.from(totalTime, at: now), isActive)
        }
    }
}

struct TimeQuantity {
    let hours: Int
    let minutes: Int
    let seconds: Int
    let at: Date
    
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
        let pastDate = Calendar.current.date(byAdding: components, to: at)!
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
        return TimeQuantity(hours: -1, minutes: -1, seconds: -1, at: Date())
    }
    
    static func from(_ timeInterval: TimeInterval, at date: Date) -> TimeQuantity {
        let time = Int(timeInterval)
        
        let seconds = (time % 60)
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        return TimeQuantity(hours: hours, minutes: minutes, seconds: seconds, at: date)
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
        let today = TimeQuantity(hours: 1, minutes: 38, seconds: 04, at: Date())
        let week = TimeQuantity(hours: 53, minutes: 43, seconds: 59, at: Date())
        let fakeStatus = TimeStatus(today: today, week: week, active: true)
        let entry = TimeEntry(date: Date(), status: fakeStatus)
        return entry
    }
    
    // Fake information for previews
    public func getSnapshot(in context: Context, completion: @escaping (TimeEntry) -> Void) {
        let today = TimeQuantity(hours: 1, minutes: 38, seconds: 04, at: Date())
        let week = TimeQuantity(hours: 53, minutes: 43, seconds: 59, at: Date())
        let fakeStatus = TimeStatus(today: today, week: week, active: true)
        let entry = TimeEntry(date: Date(), status: fakeStatus)
        completion(entry)
    }
    
    // Real information
    public func getTimeline(in context: Context, completion: @escaping (Timeline<TimeEntry>) -> Void) {
        let currentDate = Date()
        let earlyDate = Calendar.current.date(byAdding: .hour, value: 5, to: currentDate)!
        let farDate = Calendar.current.date(byAdding: .hour, value: 10, to: currentDate)!
        
        TimeLoader.fetch { (result) in
            let status: TimeStatus
            if case .success(let fetchedStatus) = result {
                status = fetchedStatus
            } else {
                let zeroDay = TimeQuantity(hours: 0, minutes: 0, seconds: 0, at: Date())
                status = TimeStatus(today: zeroDay, week: zeroDay, active: false)
            }
            
            // Zero point at present time
            let baseEntry = TimeEntry(date: currentDate, status: status)
            
            var entries: [TimeEntry] = [baseEntry]
            if (baseEntry.status.active) {
                // Optionally refresh at points offset transitions

                let startToday = baseEntry.status.today.activeRelativeDate
                let startWeek = baseEntry.status.week.activeRelativeDate
                
                let seedRefreshPoints = { (forToday: Bool, hours: Int, minutes: Int) -> () in
                    let minInterval: TimeInterval = 60 /* seconds/min */ * Double(minutes) /* min */
                    let hourInterval: TimeInterval = 60 /* seconds/min */ * 60 /* min/hour */ * Double(hours) /* hour */
                    let totalInterval = minInterval + hourInterval
                    
                    // Start today and start week are entries in the past whose delta to now gives the total value
                    let todayWithInterval = startToday.addingTimeInterval(totalInterval)
                    let weekWithInterval = startWeek.addingTimeInterval(totalInterval)
                    let targetWithInterval = forToday ? todayWithInterval : weekWithInterval
                    
                    let goalEntry = TimeQuantity(hours: hours, minutes: minutes, seconds: 0, at: targetWithInterval)
                    
                    // If target in future, schedule update
                    if targetWithInterval > currentDate {
                        let additionalSeconds = targetWithInterval.timeIntervalSinceReferenceDate - currentDate.timeIntervalSinceReferenceDate
                        
                        let peerBase = forToday ? startWeek : startToday
                        let newPeer = peerBase.addingTimeInterval(-additionalSeconds) // Roll back in time to use now as a delta mark
                        let totalPeerInterval = currentDate.timeIntervalSinceReferenceDate - newPeer.timeIntervalSinceReferenceDate
                        let peerEntry = TimeQuantity.from(totalPeerInterval, at: goalEntry.at)
                    
                        let date = forToday ? todayWithInterval : weekWithInterval
                        let todayQuantity = forToday ? goalEntry : peerEntry
                        let weekQuantity = forToday ? peerEntry : goalEntry
                        
                        let entry = TimeEntry(date: date, status: TimeStatus(today: todayQuantity, week: weekQuantity, active: status.active))
                        entries.append(entry)
                    }
                }
                
                // 10 min mark ('00:0' -> '00:')
                seedRefreshPoints(false, 0, 10)
                seedRefreshPoints(true, 0, 10)
                // 1 hour mark ('00:' -> '0')
                seedRefreshPoints(false, 1, 0)
                seedRefreshPoints(true, 1, 0)
                // 10 hour mark ('0' -> '')
                seedRefreshPoints(false, 10, 0)
                seedRefreshPoints(true, 10, 0)
            }
            
            let timeline = Timeline(entries: entries, policy: .after(status.active ? earlyDate : farDate))
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
                today: TimeQuantity(hours: 0, minutes: 6, seconds: 36, at: Date()),
                week: TimeQuantity(hours: 11, minutes: 22, seconds: 33, at: Date()),
                active: true
            )
        )).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
