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

extension Color {
    // System Colors
    static var label: Color {
        return Color(UIColor.label)
    }
    static var secondarySystemGroupedBackground: Color {
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
        var dayTime: String? = nil
        var weekTime: String? = nil
        var isActive = false
        
        let now = Date()
        let calendar = Calendar.current
        
        let dayComps = calendar.dateComponents([.day, .month, .year], from: now)
        let weekComps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)
        
        let startOfDay = calendar.date(from: dayComps)!
        let startOfWeek = calendar.date(from: weekComps)!
        
        let doneWithRange = {
            guard dayTime != nil && weekTime != nil else { return }
            
            let status = TimeStatus(today: dayTime!, week: weekTime!, active: isActive)
            print("Done with fetch")
            completion(.success(status))
        }
        
        let containerUrl = Constants.containerUrl
        let serverURLOverride = UserDefaults.init(suiteName: containerUrl)?.string(forKey: "server_url_override")
        Time.refreshShared()
        Time.shared.initialize(
            for: serverURLOverride,
            containerUrlOverride: containerUrl,
            userDefaultsSuiteName: containerUrl
        ) { error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            // Check day total
            self.getFrom(date: startOfDay) { (dayString, active) in
                dayTime = dayString
                isActive = isActive || active
                print("Day active \(active)")
                doneWithRange()
            }
            // Check week total
            self.getFrom(date: startOfWeek) { (weekString, active) in
                weekTime = weekString
                isActive = isActive || active
                print("Week active \(active)")
                doneWithRange()
            }
        }
    }
    
    static internal func getFrom(date: Date, completion: @escaping (String, Bool) -> ()) {
        Time.shared.store.getEntries(after: date) { (entries: [Entry]?, error: Error?) -> () in
            guard entries != nil && error == nil else {
                completion("XX:XX:XX", false)
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
            
            let getTimeString = { (time: Int) -> String in
                let seconds = (time % 60)
                let minutes = (time / 60) % 60
                let hours = (time / 3600)
                
                let showSeconds = true // TODO: Use app settings
                let timeString = showSeconds
                    ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                    : String(format: "%02d:%02d", hours, minutes)
                return timeString
            }
            
            completion(getTimeString(Int(totalTime)), isActive)
        }
    }
}

struct TimeStatus {
    let today: String
    let week: String
    let active: Bool
}

struct TimeEntry: TimelineEntry {
    public let date: Date
    public let status: TimeStatus
}

struct TimeTimeline: TimelineProvider {
    typealias Entry = TimeEntry
    
    public func placeholder(in context: Context) -> TimeEntry {
        let fakeStatus = TimeStatus(today: "01:38:04", week: "53:43:59", active: true)
        let entry = TimeEntry(date: Date(), status: fakeStatus)
        return entry
    }
    
    // Fake information for previews
    public func getSnapshot(in context: Context, completion: @escaping (TimeEntry) -> Void) {
        let fakeStatus = TimeStatus(today: "01:38:04", week: "53:43:59", active: true)
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
                status = TimeStatus(today: "00:00:00", week: "00:00:00", active: false)
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
            VStack(alignment: .leading, spacing: 4, content: {
                Text(entry.status.today)
                    .font(Font.system(size: 24.0, weight: .regular, design: .default).monospacedDigit())
                    .foregroundColor(entry.status.active ? Color.active : Color.label)
                Text("Today")
                    .font(Font.system(size: 10.0, weight: .regular, design: .default))
                    .foregroundColor(.label)
            })
            Spacer()
            VStack(alignment: .leading, spacing: 4, content: {
                Text(entry.status.week)
                    .font(Font.system(size: 24.0, weight: .regular, design: .default).monospacedDigit())
                    .foregroundColor(entry.status.active ? Color.active : Color.label)
                Text("This Week")
                    .font(Font.system(size: 10.0, weight: .regular, design: .default))
                    .foregroundColor(.label)
            })
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondarySystemGroupedBackground)
    }
}
