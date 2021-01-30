//
//  EntryView.swift
//  iOS
//
//  Created by Nathan Tornquist on 1/28/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct EntryView: View {
    
    typealias TimezoneOption = (name: String, value: String)
    typealias CategoryOption = (name: String, depth: Int, categoryID: Int)
    
    // MARK: - True object state
    
    var id: Int
    @State var type: EntryType
    @State var categoryID: Int
    
    @State var startedAt: Date
    @State var startedAtTimezone: String?
    
    @State var endedAt: Date?
    @State var endedAtTimezone: String?
    
    // MARK: - Picker data
    
    var timezones: [TimezoneOption]
    var categories: [CategoryOption]
    
    // MARK: - Formatters and copy
        
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy h:mm a"
        return formatter
    }()
    
    // MARK: - View management
    
    var presentingVC: UIViewController?
    var save: ((_ entry: Entry) -> ())?
    
    enum FieldType {
        case startedAt
        case startedAtTimezone
        case endedAt
        case endedAtTimezone
        case none
    }
    @State var showPicker: FieldType = .none
    func handle(picker: FieldType) {
        if self.showPicker == picker {
            self.showPicker = .none
        } else {
            self.showPicker = picker
        }
    }

    init(_ entry: Entry, timezones: [TimezoneOption], categories: [CategoryOption]) {
        // Build initial state from entry
        
        self.id = entry.id
        self._type = State(initialValue: entry.type)
        self._categoryID = State(initialValue: entry.categoryID)
        
        self._startedAt = State(initialValue: entry.startedAt)
        self._startedAtTimezone = State(initialValue: entry.startedAtTimezone)
        
        self._endedAt = State(initialValue: entry.endedAt)
        self._endedAtTimezone = State(initialValue: entry.endedAtTimezone)
        
        // Configure pickers
        
        self.timezones = timezones
        self.categories = categories
    }
    
    func getTitleRow(for field: FieldType) -> some View {
        return HStack {
            Text(self.getTitle(for: field))
            Spacer()
            Text(self.getDisplayValue(for: field))
                .foregroundColor(self.getValueColor(for: field))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.handle(picker: field)
        }
        .disabled(!self.canSet(field))
    }
    
    func getEditRow(for field: FieldType) -> some View {
        switch field {
        case .startedAt,
             .endedAt:
            let binding = field == .startedAt
                ? $startedAt
                : (Binding<Date> { () -> Date in
                    return self.endedAt ?? Date()
                } set: { (newDate) in
                    self.endedAt = newDate
                })
            let timezone = field == .startedAt
                ? self.startedAtTimezone
                : self.endedAtTimezone
            
            let datePicker = field == .startedAt
                ? DatePicker("", selection: binding)
                : DatePicker("", selection: binding, in: startedAt...)
            
            let completeDatePicker = datePicker
                .accentColor(.blue)
                .datePickerStyle(WheelDatePickerStyle())
                .environment(\.timeZone, self.getSafeTimezone(for: timezone))
            return AnyView(completeDatePicker)

        case .startedAtTimezone,
             .endedAtTimezone:
            let binding = field == .startedAtTimezone
                ? $startedAtTimezone
                : $endedAtTimezone
            let timezonePicker = Picker("", selection: binding) {
                ForEach(0 ..< timezones.count) {
                    Text(self.timezones[$0].0).tag(self.timezones[$0].1 as String?)
                }
            }.pickerStyle(InlinePickerStyle())
            return AnyView(timezonePicker)

        case .none:
            return AnyView(EmptyView())
        }
    }
    
    var body: some View {
        // Using a tag on the picker directly did not work as-expected
        // It was using the int as an index, instead of a tag
        let categoryBinding = Binding<Int>(
            get: {
                return (self.categories.firstIndex { (category) -> Bool in
                    return category.2 == categoryID
                } ?? -1)
            },
            set: {
                let hasItem = self.categories.indices.contains($0)
                let isRoot = hasItem && self.categories[$0].depth == 0
                if !isRoot {
                    self.categoryID = self.categories[$0].2
                }
            }
        )
        
        return VStack {
            NavigationView {
                Form {
                    Section {
                        Picker("Category", selection: categoryBinding) {
                            ForEach(0 ..< categories.count) {
                                let name = self.categories[$0].0
                                let offset = self.categories[$0].1
                                let offsetString = String(repeating: "    ", count: offset)

                                Text(offsetString + name)
                            }
                        }.labelsHidden()
                    }
                    Section {
                        Picker(selection: self.$type, label: Text("Type")) {
                            Text("Range").tag(EntryType.range)
                            Text("Event").tag(EntryType.event)
                        }.pickerStyle(SegmentedPickerStyle())
                    }

                    Section {
                        self.getTitleRow(for: .startedAt)
                        if self.showPicker == .startedAt {
                            self.getEditRow(for: .startedAt)
                        }

                        self.getTitleRow(for: .startedAtTimezone)
                        if self.showPicker == .startedAtTimezone {
                            self.getEditRow(for: .startedAtTimezone)
                        }
                    }

                    if type == .range {
                        Section {
                            self.getTitleRow(for: .endedAt)
                            if self.showPicker == .endedAt {
                                self.getEditRow(for: .endedAt)
                            }

                            self.getTitleRow(for: .endedAtTimezone)
                            if self.showPicker == .endedAtTimezone {
                                self.getEditRow(for: .endedAtTimezone)
                            }
                        }
                    }
                }
                .navigationTitle("Edit Entry")
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            self.presentingVC?.presentedViewController?.dismiss(animated: true)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            self.save?(
                                Entry(
                                    id: self.id,
                                    type: self.type,
                                    categoryID: self.categoryID,
                                    startedAt: self.startedAt,
                                    startedAtTimezone: self.startedAtTimezone,
                                    endedAt: self.type == .range ? self.endedAt : nil,
                                    endedAtTimezone: self.type == .range ? self.endedAtTimezone : nil
                                )
                            )
                            self.presentingVC?.presentedViewController?.dismiss(animated: true)
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Timezone helper methods
    
    func getTimezoneIndex(for option: String?) -> Array<(String, String)>.Index? {
        return self.timezones.firstIndex(where: { (timezone) -> Bool in
            return timezone.1 == option
        })
    }
    
    func getSafeTimezone(for option: String?) -> TimeZone {
        let timezone = TimeZone(identifier: option ?? "-") ?? TimeZone.current
        return timezone
    }
    
    // MARK: - View Helpers
    
    func canSet(_ field: FieldType) -> Bool {
        switch field {
        case .startedAt,
             .startedAtTimezone:
            return true
        case .endedAt:
            return self.type == .range
        case .endedAtTimezone:
            return self.type == .range && self.endedAt != nil
        case .none:
            return false
        }
    }
    
    func isSet(_ field: FieldType) -> Bool {
        switch field {
        case .startedAt:
            return true
        case .startedAtTimezone:
            return self.startedAtTimezone != nil
        case .endedAt:
            return self.endedAt != nil
        case .endedAtTimezone:
            return self.endedAtTimezone != nil
        case .none:
            return false
        }
    }
    
    func getValueColor(for field: FieldType) -> Color {
        let canSet = self.canSet(field)
        let isSet = self.isSet(field)
        
        if canSet && !isSet {
            return Color(.link)
        } else if !canSet {
            return Color(.secondaryLabel)
        } else if self.showPicker == field {
            return Color(.systemGreen)
        } else {
            return Color(.label)
        }
    }
    
    func getTimezoneDisplay(for option: String?) -> String {
        if let index = self.getTimezoneIndex(for: option) {
            return self.timezones[index].0
        } else {
            return NSLocalizedString("No value", comment: "")
        }
    }
    
    func getTimeDisplay(for date: Date?) -> String {
        return date != nil ? dateFormatter.string(from: date!) : NSLocalizedString("No value", comment: "")
    }
    
    func getDisplayValue(for field: FieldType) -> String {
        switch field {
        case .startedAt:
            return self.getTimeDisplay(for: self.startedAt)
        case .startedAtTimezone:
            return self.getTimezoneDisplay(for: self.startedAtTimezone)
        case .endedAt:
            return self.getTimeDisplay(for: self.endedAt)
        case .endedAtTimezone:
            return self.getTimezoneDisplay(for: self.endedAtTimezone)
        case .none:
            return ""
        }
    }
    
    func getTitle(for field: FieldType) -> String {
        switch field {
        case .startedAt:
            return self.type == .range
                ? NSLocalizedString("Start time", comment: "")
                : NSLocalizedString("Event time", comment: "")
        case .endedAt:
            return NSLocalizedString("End time", comment: "")
        case .startedAtTimezone,
             .endedAtTimezone:
            return NSLocalizedString("Timezone", comment: "")
        case .none:
            return ""
        }
    }
    
}

#if DEBUG
struct EntryView_Previews: PreviewProvider {
    static var previews: some View {
        let allTimezones = TimeZone.knownTimeZoneIdentifiers
        let timezoneLabels = allTimezones.map({
            $0.replacingOccurrences(of: "/", with: " > ")
                .replacingOccurrences(of: "_", with: " ")
        })
        let timezoneValues = allTimezones
        let timezones = Array(zip(timezoneLabels, timezoneValues))
        
        let categoriesRaw = [
            (["Account 1"], 1),
            
            (["Account 1", "Personal"], 16),
            (["Account 1", "Personal", "Task 1"], 6),
            (["Account 1", "Personal", "Task 1", "Subtask X"], 7),
            (["Account 1", "Personal", "Task 2"], 8),
            (["Account 1", "Personal", "Task 3"], 9),
            (["Account 1", "Personal", "Task 3", "Subtask Y"], 10),
            (["Account 1", "Personal", "Task 3", "Subtask Z"], 11),
            
            (["Account 1", "Work"], 2),
            (["Account 1", "Work", "Job A"], 3),
            (["Account 1", "Work", "Job B"], 4),
            (["Account 1", "Work", "Job C"], 5),
            
            (["Account 2"], 12),
            (["Account 2", "A"], 13),
            (["Account 2", "B"], 14),
            (["Account 2", "C"], 15)
        ]
        
        let categoriesFormatted = categoriesRaw.map { (incoming) -> EntryView.CategoryOption in
            let names: [String] = incoming.0
            let categoryID: Int = incoming.1
            
            return (name: names.last ?? "", depth: names.count - 1, categoryID: categoryID)
        }

        return EntryView(
            Entry(
                id: 1,
                type: .range,
                categoryID: 8,
                startedAt: Date(),
                startedAtTimezone: "America/Chicago",
                endedAt: nil,
                endedAtTimezone: nil
            ),
            timezones: timezones,
            categories: categoriesFormatted
        )
//         .environment(\.colorScheme, .dark)
    }
}
#endif
