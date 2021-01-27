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
    static func fetch(for reference: Date, completion: @escaping (Result<TimeEntry, Error>) -> Void) {
        let calendar = Calendar.current
        let weekComps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: reference)
        let startOfWeek = calendar.date(from: weekComps)!
        
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
            
            Time.shared.store.getEntries(after: startOfWeek) { (entries: [Entry]?, error: Error?) -> () in
                guard error == nil else {
                    completion(.failure(error!))
                    return
                }
                
                let dayData = self.get(current: .day)
                let weekData = self.get(current: .week)

                let entry = TimeEntry(
                    date: reference,
                    today: dayData.quantity,
                    week: weekData.quantity,
                    active: dayData.active || weekData.active
                )
                completion(.success(entry))
            }
        }
    }
    
    static internal func get(current timePeriod: TimePeriod) -> (quantity: TimeQuantity, active: Bool) {
        let analysisResult = Time.shared.analyzer.evaluate(
            TimeRange(current: timePeriod),
            groupBy: timePeriod,
            perform: [.calculateTotal]
        )
        let result = analysisResult.values.first?.first(where: { $0.operation == .calculateTotal })
        
        let quantity = result != nil ? TimeQuantity.from(result!.duration) : TimeQuantity.from(0)
        let active = result?.open ?? false
        
        return (quantity: quantity, active: active)
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
    
    func relativeDate(to reference: Date) -> Date {
        let components = DateComponents(hour: -self.hours, minute: -self.minutes, second: -self.seconds)
        let pastDate = Calendar.current.date(byAdding: components, to: reference)!
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
    
    static func from(_ timeInterval: TimeInterval) -> TimeQuantity {
        let time = Int(timeInterval)
        
        let seconds = (time % 60)
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        return TimeQuantity(hours: hours, minutes: minutes, seconds: seconds)
    }
}

struct TimeEntry: TimelineEntry {
    public let date: Date
    public let today: TimeQuantity
    public let week: TimeQuantity
    public let active: Bool
}

struct TimeTimeline: TimelineProvider {
    typealias Entry = TimeEntry
    
    public func placeholder(in context: Context) -> TimeEntry {
        let today = TimeQuantity(hours: 1, minutes: 38, seconds: 04)
        let week = TimeQuantity(hours: 53, minutes: 43, seconds: 59)
        let fakeEntry = TimeEntry(date: Date(), today: today, week: week, active: true)
        return fakeEntry
    }
    
    // Fake information for previews
    public func getSnapshot(in context: Context, completion: @escaping (TimeEntry) -> Void) {
        let today = TimeQuantity(hours: 1, minutes: 38, seconds: 04)
        let week = TimeQuantity(hours: 53, minutes: 43, seconds: 59)
        let fakeEntry = TimeEntry(date: Date(), today: today, week: week, active: true)
        completion(fakeEntry)
    }
    
    // Real information
    public func getTimeline(in context: Context, completion: @escaping (Timeline<TimeEntry>) -> Void) {
        let currentDate = Date()
        
        let earlyRefresh = Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)!
        let farRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: currentDate)!
        
        // Identify refresh point slightly into tomorrow (to avoid issues with preload at the 0 point)
        let startOfToday = Calendar.current.startOfDay(for: currentDate)
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        let tomorrowRefresh = Calendar.current.date(byAdding: .minute, value: 2, to: startOfTomorrow)!
        
        TimeLoader.fetch(for: currentDate) { (result) in
            let baseEntry: TimeEntry
            if case .success(let fetchedEntry) = result {
                baseEntry = fetchedEntry
            } else {
                let zeroDay = TimeQuantity(hours: 0, minutes: 0, seconds: 0)
                baseEntry = TimeEntry(date: currentDate, today: zeroDay, week: zeroDay, active: false)
            }

            var entries: [TimeEntry] = [baseEntry]
            if (baseEntry.active) {
                // Optionally refresh at points offset transitions

                let startToday = baseEntry.today.relativeDate(to: currentDate)
                let startWeek = baseEntry.week.relativeDate(to: currentDate)
                
                let seedRefreshPoints = { (forToday: Bool, hours: Int, minutes: Int) -> () in
                    let minInterval: TimeInterval = 60 /* seconds/min */ * Double(minutes) /* min */
                    let hourInterval: TimeInterval = 60 /* seconds/min */ * 60 /* min/hour */ * Double(hours) /* hour */
                    let totalInterval = minInterval + hourInterval
                    
                    // Start today and start week are entries in the past whose delta to now gives the total value
                    let todayWithInterval = startToday.addingTimeInterval(totalInterval)
                    let weekWithInterval = startWeek.addingTimeInterval(totalInterval)
                    let targetWithInterval = forToday ? todayWithInterval : weekWithInterval
                    
                    let goalEntry = TimeQuantity(hours: hours, minutes: minutes, seconds: 0)
                    
                    // If target in future, schedule update
                    if targetWithInterval > currentDate {
                        let additionalSeconds = targetWithInterval.timeIntervalSinceReferenceDate - currentDate.timeIntervalSinceReferenceDate
                        
                        let peerBase = forToday ? startWeek : startToday
                        let newPeer = peerBase.addingTimeInterval(-additionalSeconds) // Roll back in time to use now as a delta mark
                        let totalPeerInterval = currentDate.timeIntervalSinceReferenceDate - newPeer.timeIntervalSinceReferenceDate
                        let peerEntry = TimeQuantity.from(totalPeerInterval)
                    
                        let date = forToday ? todayWithInterval : weekWithInterval
                        let todayQuantity = forToday ? goalEntry : peerEntry
                        let weekQuantity = forToday ? peerEntry : goalEntry
                        
                        let entry = TimeEntry(date: date, today: todayQuantity, week: weekQuantity, active: baseEntry.active)
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
            
            let refreshDate = [
                // Anticipated refresh point
                baseEntry.active ? earlyRefresh : farRefresh,
                // Required refresh point (for correct today display)
                tomorrowRefresh
            ].min()!
            
            let timeline = Timeline(entries: entries, policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct TimeWidgetView : View {
    let entry: TimeEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            getBlock(forToday: true, andEntry: entry)
            Spacer()
            getBlock(forToday: false, andEntry: entry)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Theme.background)
    }
    
    func getBlock(forToday: Bool, andEntry value: TimeEntry) -> some View {
        let title = forToday ? "Today" : "This Week"
        let data = forToday ? value.today : value.week
        
        return VStack(alignment: .leading, spacing: 4, content: {
            (
                value.active
                    ? (Text(data.activePrefix) + Text(data.relativeDate(to: value.date), style: .timer))
                    : Text(data.frozenDisplayValue)
            )
                .font(Font.system(size: 24.0, weight: .regular, design: .default).monospacedDigit())
                .foregroundColor(value.active ? Theme.active : Theme.label)
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
            today: TimeQuantity(hours: 0, minutes: 6, seconds: 36),
            week: TimeQuantity(hours: 11, minutes: 22, seconds: 33),
            active: true
        )).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
