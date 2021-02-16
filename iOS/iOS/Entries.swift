//
//  Entries.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct Entries: View {
    
    @EnvironmentObject var warehouse: Warehouse
    
    // Shared between all instances
    static var dateFormatters: [String:DateFormatter] = [:]

    var body: some View {
        List {
            ForEach(self.warehouse.entries) { (entry) in
                let active = entry.endedAt == nil && entry.type == .range
                TitleSubtitleActionView(
                    title: getName(entry),
                    subtitle: getTimeString(for: entry),
                    action: active ? .stop : .none,
                    active: active,
                    onTap: {
                        if active {
                            self.warehouse.time?.store.stop(entry: entry, completion: nil)
                        }
                    }
                )
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .navigationTitle("Entries")
    }
    
    func getName(_ entry: Entry) -> String {
        guard let category = self.warehouse.time?.store.categories.first(where: { $0.id == entry.categoryID }),
              let accountTree = self.warehouse.time?.store.categoryTrees[category.accountID],
              let categoryTree = accountTree.findItem(withID: category.id)
        else {
            return "Error"
        }
        
        var displayNameParts = [categoryTree.node.name]
        var position = categoryTree.parent
        while position != nil {
            // Make sure exists and is not root
            if position != nil && position?.parent != nil {
                displayNameParts.append(position!.node.name)
            }
            position = position?.parent
        }
        
        
        let displayName = displayNameParts.reversed().joined(separator: " > ")
        
        return displayName
    }
    
    // MARK: - Time Formatting
    
    func getTimeString(for entry: Entry) -> String {
        let startedAtString = self.format(time: entry.startedAt, with: entry.startedAtTimezone)
        let endedAtString = entry.endedAt != nil ? self.format(time: entry.endedAt!, with: entry.endedAtTimezone) : nil
        
        var timeText = ""
        if entry.type == .event {
            timeText = "@ \(startedAtString)"
        } else if entry.endedAt == nil {
            timeText = "\(startedAtString) - \(NSLocalizedString("Present", comment: ""))"
        } else {
            // Depends on stable string formatting
            let sameDay = endedAtString != nil && (startedAtString.prefix(8) == endedAtString!.prefix(8))
            if !sameDay {
                timeText = "\(startedAtString) - \(endedAtString!)"
            } else {
                let endedAtWithoutDate = endedAtString!.dropFirst(9)
                timeText = "\(startedAtString) - \(endedAtWithoutDate)"
            }
        }
        return timeText
    }
    
    func format(time: Date, with timezoneIdentifier: String?) -> String {
        let defaultTimezone = TimeZone.autoupdatingCurrent
        let safeTimezone = timezoneIdentifier ?? defaultTimezone.identifier
        if (Entries.dateFormatters[safeTimezone] == nil) {
            let timezone = TimeZone(identifier: safeTimezone) ?? defaultTimezone
            if (Entries.dateFormatters[timezone.identifier] == nil) {
                let newFormatter = DateFormatter.init()
                newFormatter.dateFormat = "MM/dd/YY hh:mm a zzz"
                newFormatter.timeZone = timezone
                Entries.dateFormatters[safeTimezone] = newFormatter
            }
        }
        
        return Entries.dateFormatters[safeTimezone]!.string(from: time)
    }
}
