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
    
    @State var selectedEntry: Entry? = nil
    @State var handlingId: [Int: Bool] = [:]
    
    @State var exportLoading: Bool = false
    @State var showExportDialog: Bool = false
    @State var exportDocument: ReportDocument? = nil
    
    var timezones: [(String, String)]
   
    var outputDateFormatter: DateFormatter = DateFormatter()
    
    // Shared between all cells
    static var dateFormatters: [String:DateFormatter] = [:]
    
    init() {
        // Prepare timezone list
        let allTimezones = TimeZone.knownTimeZoneIdentifiers
        let timezoneLabels = allTimezones.map({
            $0.replacingOccurrences(of: "/", with: " > ")
                .replacingOccurrences(of: "_", with: " ")
        })
        let timezoneValues = allTimezones
        self.timezones = Array(zip(timezoneLabels, timezoneValues))
        
        self.outputDateFormatter.dateFormat = "yyyy-MM-dd"
        self.outputDateFormatter.timeZone = TimeZone.current // Sync with analyzer
        self.outputDateFormatter.locale = Locale.current // Sync with analyzer
    }
    
    var body: some View {
        let showEdit = Binding<Bool>(
            get: {
                self.selectedEntry != nil
            },
            set: { newBool in
                if !newBool {
                    self.selectedEntry = nil
                }
            }
        )
                
        return List(self.warehouse.entries) { (entry) in
            let active = entry.endedAt == nil && entry.type == .range
            TitleSubtitleActionView(
                title: getName(entry),
                subtitle: getTimeString(for: entry),
                action: active ? .stop : .none,
                active: active,
                loading: handlingId[entry.id] ?? false,
                onTapButton: {
                    if active {
                        Mainify {
                            handlingId[entry.id] = true
                        }
                        self.warehouse.time?.store.stop(entry: entry, completion: { _ in
                            Mainify { handlingId[entry.id] = false }
                        })
                    }
                }
            )
            .onTapGesture {
                self.selectedEntry = entry
            }
        }
        .listStyle(.inset)
        .sheet(
            isPresented: showEdit, content: {
                EditEntry(
                    self.selectedEntry!,
                    show: showEdit,
                    timezones: self.timezones,
                    categories: self.identifyCategoryOptions(),
                    onSave: saveEdit,
                    onDelete: deleteEntry
                )
            }
        )
        .navigationTitle("Entries")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.buildExport(
                        doneLoading: self.$exportLoading,
                        readyForUI: self.$showExportDialog
                    )
                    self.exportLoading = true
                } label: {
                    if self.exportLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .fileExporter(
            isPresented: self.$showExportDialog,
            document: self.exportDocument,
            contentType: .plainText,
            defaultFilename: "\(self.outputDateFormatter.string(from: Date()))_time_entries_export.csv"
        ) { _ in }
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
    
    // MARK: - Category Options
    
    func identifyCategoryOptions() -> [EditEntry.CategoryOption] {
        // Prepare/flatten category data
        let accountIDs = self.warehouse.time?.store.accountIDs.sorted() ?? []
        let categoryTreesByAccount = accountIDs.compactMap { self.warehouse.time?.store.categoryTrees[$0]?.listCategoryTrees() }
        let categories = categoryTreesByAccount.flatMap { (categoryTrees) -> [EditEntry.CategoryOption] in
            return categoryTrees.map { (categoryTree) -> EditEntry.CategoryOption in
                let isRoot = categoryTree.parent == nil
                let name = isRoot ? "Account \(categoryTree.node.accountID)" : categoryTree.node.name
                return (name: name, depth: categoryTree.depth, categoryID: categoryTree.node.id)
            }
        }
        
        return categories
    }
    
    // MARK: - On Entry Save
    
    func saveEdit(_ newEntry: Entry) -> () {
        guard let entry = self.selectedEntry else { return }
        
        let changedCategory = entry.categoryID != newEntry.categoryID
        let changedType = entry.type != newEntry.type
        let changedStartedAt = entry.startedAt != newEntry.startedAt
        let changedStartedAtTimezone = entry.startedAtTimezone != newEntry.startedAtTimezone
        let changedEndedAt = entry.endedAt != newEntry.endedAt
        let changedEndedAtTimezone = entry.endedAtTimezone != newEntry.endedAtTimezone

        let someChanged = changedCategory || changedType || changedStartedAt || changedStartedAtTimezone || changedEndedAt || changedEndedAtTimezone
        guard someChanged else {
            self.selectedEntry = nil
            return
        }

        let newCategory = changedCategory
            ? self.warehouse.time?.store.categories.first(where: { $0.id == newEntry.categoryID })
            : nil

        self.warehouse.time?.store.update(
            entry: entry,
            setCategory: newCategory,
            setType: changedType ? newEntry.type : nil,
            setStartedAt: changedStartedAt ? newEntry.startedAt : nil,
            setStartedAtTimezone: changedStartedAtTimezone ? newEntry.startedAtTimezone : nil,
            setEndedAt: changedEndedAt ? newEntry.endedAt : nil,
            setEndedAtTimezone: changedEndedAtTimezone ? newEntry.endedAtTimezone : nil,
            completion: { (success) -> Void in
                if success {
                    self.selectedEntry = nil
                }
            }
        )
    }
    
    func deleteEntry() -> () {
        guard let entry = self.selectedEntry else { return }
        
        self.warehouse.time?.store.delete(entry: entry, completion: { (success) in
            self.selectedEntry = nil
        })
    }
    
    // MARK: - Export Data
    
    func buildExport(
        doneLoading: Binding<Bool>,
        readyForUI: Binding<Bool>
    ) {
        // Rebuild File
        DispatchQueue.global(qos: .background).async {
            var rows = ["Type, Path, Name, Started At, Started At Timezone, Ended At, Ended At Timezone"]
            
            var nameCache: [Int: String] = [:]
            var pathCache: [Int: String] = [:]
            
            let formatter = ISO8601DateFormatter()
            
            self.warehouse.entries.forEach { entry in
                let type = entry.type.rawValue
                let startedAt = formatter.string(from: entry.startedAt)
                let startedAtTimezone = entry.startedAtTimezone ?? ""
                let endedAt = entry.endedAt != nil ? formatter.string(from: entry.endedAt!) : ""
                let endedAtTimezone = entry.endedAtTimezone ?? ""
                
                var name = nameCache[entry.categoryID]
                if name == nil {
                    name = self.warehouse.getName(for: entry.categoryID)
                    nameCache[entry.categoryID] = name
                }
                var path = pathCache[entry.categoryID]
                if path == nil {
                    path = self.warehouse.getParentHierarchyName(for: entry.categoryID)
                    pathCache[entry.categoryID] = path
                }

                let safeName = (name?.contains(",") ?? false) ? "\"\(name!)\"" : (name ?? "")
                let safePath = (path?.contains(",") ?? false) ? "\"\(path!)\"" : (path ?? "")
                
                rows.append("\(type), \(safePath), \(safeName), \(startedAt), \(startedAtTimezone), \(endedAt), \(endedAtTimezone)")
            }
            
            let file = rows.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.exportDocument = ReportDocument(message: file)
                
                doneLoading.wrappedValue = false
                readyForUI.wrappedValue = true
            }
        }
    }
}
