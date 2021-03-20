//
//  ImportWizard.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/18/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
import TimeSDK

struct ImportWizard: View {
    
    @Binding var show: Bool
    
    @State var url: URL? = nil
    @State var delimiter: String = ","
        
    @State var importer: FileImporter? = nil
    
    @State var loadingData: Bool = false
    @State var loadingError: Bool = false
    
    @State var step: Step = .welcome
        
    enum Step {
        case welcome
        case loadFile
        case buildTree
        case processDates
        case review
    }
        
    var body: some View {
        NavigationView {
            Form {
                if step == .welcome {
                    WelcomeStep(step: $step)
                }
                
                if step == .loadFile {
                    LoadFileStep(importer: $importer, step: $step)
                }
                
                if self.step == .buildTree {
                    BuildTreeStep(importer: $importer, step: $step)
                }
                 
                if self.step == .processDates {
                    ParseDatesStep(importer: $importer, step: $step)
                }
                 
                if self.step == .review {
                    ReviewStep(importer: $importer, show: $show)
                }
            }.navigationTitle("Import Wizard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // TODO: Show alert if actions started
                        self.show = false
                    }
                }
            }
        }
    }
}

fileprivate struct WelcomeStep: View {
    @Binding var step: ImportWizard.Step
    
    var body: some View {
        Section(header: Text("Getting started").titleStyle()) {
            Text("""
This wizard will guide you through the process of importing records into Time from csv files.

The rows in the files should correspond to actual time records (ranges or events) with additional data describing the category that the records coorespond to.

Time holds data in a nested structure. You have a top-level account with categories under it, and further sub-categories under those. There are no limits to how deep the nesting can be, but each layer must be identified by a column in the incoming file.
""").padding(.top, 8)
            Button(action: {
                self.step = .loadFile
            }, label: {
                Text("Begin")
            })
        }
    }
}

fileprivate struct LoadFileStep: View {
    @State var showFilePicker: Bool = false
    
    @State var url: URL? = nil
    @State var delimiter: String = ","
        
    var importer: Binding<FileImporter?>
    @Binding var step: ImportWizard.Step
    
    @State var loadingData: Bool = false
    @State var loadingError: Bool = false
        
    var body: some View {
        let urlBinding = Binding<URL?>(
            get: {
                return self.url
            },
            set: { (newURL) in
                self.url = newURL
                self.importer.wrappedValue = nil
                self.loadingError = false
            }
        )
        let delimiterBinding = Binding<String>(
            get: {
                return self.delimiter
            },
            set: { (newDelimiter) in
                self.delimiter = newDelimiter
                self.importer.wrappedValue = nil
                self.loadingError = false
            }
        )
        
        Section(header: Text("Select file").titleStyle()) {
            Button(self.url != nil ? url!.lastPathComponent : "Choose file") {
                self.showFilePicker = true
            }
            .sheet(isPresented: $showFilePicker, content: {
                ImportDocumentPicker(url: urlBinding)
            })
        }
        
        if self.url != nil {
            Section(header: Text("Set delimiter").titleStyle()) {
                Text("""
Common delimiters include: ,;|
""").padding(.top, 8)
                if delimiter.count > 1 {
                    Text("⚠️ Delimiter must be a single character")
                        .foregroundColor(Color(.systemRed))
                }
                HStack {
                    Text("Enter delimiter:")
                    TextField("Delimiter", text: delimiterBinding)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        
        if self.url != nil && self.delimiter.count == 1 {
            Section(header: Text("Load data").titleStyle()) {
                Text("Attempt to load the data from the provided file with the provided delimiter.").padding(.top, 8)
                if loadingError {
                    Text("⚠️ Unable to read contents of file")
                        .foregroundColor(Color(.systemRed))
                }
                Button(action: {
                    let delimiterIndex = self.delimiter.index(self.delimiter.startIndex, offsetBy: 0)
                    let importer = FileImporter(
                        fileURL: self.url!,
                        separator: self.delimiter[delimiterIndex]
                    )
                    self.loadingData = true
                    DispatchQueue.global(qos: .background).async {
                        do {
                            try importer.loadData()
                            DispatchQueue.main.async {
                                self.importer.wrappedValue = importer
                                self.loadingData = false
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.loadingError = true
                                self.loadingData = false
                            }
                        }
                    }
                }, label: {
                    Text("Load data")
                }).disabled(self.loadingData)
            }
        }
        
        if self.importer.wrappedValue != nil {
            Section(header: Text("Verify").titleStyle()) {
                HStack {
                    VStack {
                        HStack {
                            Text("Columns")
                            Spacer()
                        }
                        HStack {
                            Text("Rows")
                            Spacer()
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        HStack {
                            Text("\(self.importer.wrappedValue!.columns?.count ?? 0)")
                            Spacer()
                        }
                        HStack {
                            Text("\(self.importer.wrappedValue!.rows ?? 0)")
                            Spacer()
                        }
                    }
                }
                Button(action: {
                    self.step = .buildTree
                }, label: {
                    Text("Continue")
                })
            }
        }
    }
}

fileprivate struct BuildTreeStep: View {
    var importer: Binding<FileImporter?>
    @Binding var step: ImportWizard.Step
    
    struct Column: Identifiable {
        let id: UUID
        var number: Int
        let name: String
        
        init(_ name: String) {
            self.id = UUID()
            self.number = 1
            self.name = name
        }
    }
    
    func renumberColumns() {
        let correcttedColumns = self.treeColumns.enumerated().map { (element) -> Column in
            var newColumn = Column(element.element.name)
            newColumn.number = element.offset + 1 // Start at 1
            return newColumn
        }
        self.treeColumns = correcttedColumns
    }

    @State var treeColumns: [Column] = []
    @State var didEvaluate: Bool = false
    
    var body: some View {
        let addColumnBinding = Binding<String>(
            get: { return "" },
            set: { (newColumn) in
                self.treeColumns.append(Column(newColumn))
                self.renumberColumns()
                self.didEvaluate = false
            }
        )
        
        Section(header: Text("Identify tree").titleStyle()) {
            Text("""
Select the columns to use when parsing the tree.

Choose the parent column, then child, then grandchild, etc. You may choose as many columns as you wish, with a minimum of one column required.
""").padding(.top, 8)
            Picker(selection: addColumnBinding, label: Text("Add Column"), content: {
                ForEach(
                    (self.importer.wrappedValue?.columns ?? [])
                        .filter({ (columnName) in
                            return !self.treeColumns.contains { (column) -> Bool in
                                return column.name == columnName
                            }
                        }),
                    id: \.self) { (column) in
                    Text(column)
                }
            })
            
            if (self.treeColumns.count > 0) {
                ForEach(self.treeColumns) { (column) in
                    HStack {
                        Text("\(column.number).")
                        Text(column.name)
                        Spacer()
                        Button(action: {
                            self.treeColumns = self.treeColumns.filter({ $0.id != column.id})
                            self.renumberColumns()
                            self.didEvaluate = false
                        }, label: {
                            Image(systemName: "trash")
                        }).buttonStyle(PlainButtonStyle())
                        .foregroundColor(Color(.systemRed))
                    }
                }
            }
            
            Button(action: {
                self.importer.wrappedValue?.categoryColumns = self.treeColumns.map({ $0.name })
                do {
                    try self.importer.wrappedValue?.buildCategoryTree()
                    self.didEvaluate = true
                } catch {
                    // No clear error resolution present
                }
            }, label: {
                Text("Evaluate")
            }).disabled(self.treeColumns.count == 0)
        }
        
        if self.didEvaluate {
            Section(header: Text("Confirm results").titleStyle()) {
                Text("""
The following tree roots were identified:

\(self.importer.wrappedValue?.rootCategories?.joined(separator: ", ") ?? "Unknown")
""").padding(.top, 8)
                Button(action: {
                    self.step = .processDates
                }, label: {
                    Text("Continue")
                }).disabled(self.treeColumns.count == 0)
            }
        }
    }
}

fileprivate struct ParseDatesStep: View {
    var importer: Binding<FileImporter?>
    @Binding var step: ImportWizard.Step
    
    @State var dateTimeColumns: Bool = true
    @State var dateColumn: String = ""
    @State var startColumn: String = ""
    @State var endColumn: String = ""
    
    @State var dateFormat: String = "M/d/yy"
    @State var timeFormat: String = "h:mm a"
    @State var timezone: String = TimeZone.current.abbreviation() ?? "CST"
    
    @State var hasTestedFormatting: Bool = false
    @State var testParseStartRaw: String? = nil
    @State var testParseStartParsed: String? = nil
    
    enum DateTimeColumnType {
        case date
        case start
        case end
    }
    
    func availableColumns(for selfColumn: DateTimeColumnType) -> [String] {
        guard let columns = self.importer.wrappedValue?.columns else {
            return []
        }
        let columnsForCategories = self.importer.wrappedValue?.categoryColumns ?? []
        let selectedDateColumns = [
            (self.dateTimeColumns ? self.dateColumn : ""),
            self.startColumn,
            self.endColumn
        ].filter({ $0 != "" }).map({ $0! })
        
        var remainingColumns = columns.filter { (columnName) -> Bool in
            if columnsForCategories.contains(columnName) {
                return false
            }
            if selectedDateColumns.contains(columnName) {
                return false
            }
            return true
        }
        
        // Inject self for display
        if selfColumn == .date && self.dateColumn != "" {
            remainingColumns.append(self.dateColumn)
        }
        if selfColumn == .start && self.startColumn != "" {
            remainingColumns.append(self.startColumn)
        }
        if selfColumn == .end && self.endColumn != "" {
            remainingColumns.append(self.endColumn)
        }
        
        return remainingColumns
    }
    
    func readyToTest() -> Bool {
        let requiredFields: [String] = self.dateTimeColumns
            ? [
                self.dateColumn,
                self.startColumn,
                self.endColumn,
                self.dateFormat,
                self.timeFormat,
                self.timezone
            ] : [
                self.startColumn,
                self.endColumn,
                self.timezone
            ]
        
        let hasAllFields = requiredFields.map({ $0 != "" }).reduce(true, { $0 && $1 })
        return hasAllFields
    }
    
    var body: some View {
        let dateTimeBinding = Binding<Bool>(
            get: {
                return self.dateTimeColumns
            },
            set: { (newDateTimeType) in
                self.dateTimeColumns = newDateTimeType
                if self.dateTimeColumns == false { // Unix
                    self.dateColumn = ""
                }
                self.hasTestedFormatting = false
            }
        )
        
        Section(header: Text("Specify date format").titleStyle()) {
            Picker("Column style", selection: dateTimeBinding) {
                Text("Date/Time").tag(true)
                Text("Unix").tag(false)
            }.pickerStyle(SegmentedPickerStyle())
                                    
            if self.dateTimeColumns {
                Picker("Date column", selection: $dateColumn.onChange({ _ in self.hasTestedFormatting = false })) {
                    ForEach(availableColumns(for: .date), id: \.self) { (column) in
                        Text(column)
                    }
                }
            }
            
            Picker(
                self.dateTimeColumns ? "Start time column" : "Start timestamp",
                selection: $startColumn.onChange({ _ in self.hasTestedFormatting = false })
            ) {
                ForEach(availableColumns(for: .start), id: \.self) { (column) in
                    Text(column)
                }
            }
            
            Picker(
                self.dateTimeColumns ? "End time column" : "End timestamp",
                selection: $endColumn.onChange({ _ in self.hasTestedFormatting = false })
            ) {
                ForEach(availableColumns(for: .end), id: \.self) { (column) in
                    Text(column)
                }
            }
            
            if self.dateTimeColumns {
                HStack {
                    Text("Date format")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    TextField("M/d/yy", text: $dateFormat.onChange({ _ in self.hasTestedFormatting = false }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                
                HStack {
                    Text("Time format")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    TextField("h:mm a", text: $timeFormat.onChange({ _ in self.hasTestedFormatting = false }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            
            HStack {
                Text("Timezone")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                TextField("Timezone", text: $timezone.onChange({ _ in self.hasTestedFormatting = false }))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            
            Button("Test formatting") {
                if self.dateTimeColumns {
                    // Parse as Date/Time
                    do {
                        let result = try self.importer.wrappedValue?.setDateTimeParseRules(
                            dateColumn: self.dateColumn,
                            startTimeColumn: self.startColumn,
                            endTimeColumn: self.endColumn,
                            dateFormat: self.dateFormat,
                            timeFormat: self.timeFormat,
                            timezoneAbbreviation: self.timezone,
                            testFormat: "MMM d, y @ h:mm a zzz"
                        )
                        
                        self.testParseStartRaw = result?.startRaw
                        self.testParseStartParsed = result?.startParsed
                    } catch {
                        // Show error
                        return
                    }
                } else {
                    // Parse as Unix
                    do {
                        let result = try self.importer.wrappedValue?.setDateTimeParseRules(
                            startUnixColumn: self.startColumn,
                            endUnixColumn: self.endColumn,
                            timezoneAbbreviation: self.timezone,
                            testFormat: "MMM d, y @ h:mm a zzz"
                        )
                        
                        self.testParseStartRaw = result?.startRaw
                        self.testParseStartParsed = result?.startParsed
                    } catch {
                        // Show error
                        return
                    }
                }
                
                self.hasTestedFormatting = true
            }.disabled(!self.readyToTest())
        }
        
        if self.hasTestedFormatting {
            Section(header: Text("Confirm format").titleStyle()) {
                Text("First row raw start: \(self.testParseStartRaw ?? "<error>")")
                Text("First row parsed start: \(self.testParseStartParsed ?? "<error>")")
                Button("Confirm") {
                    do {
                        try self.importer.wrappedValue?.parseAll()
                        self.step = .review
                    } catch {
                        // Show error
                    }
                }
            }
        }
    }
}

fileprivate struct ReviewStep: View {
    var importer: Binding<FileImporter?>
    @Binding var show: Bool
    
    var body: some View {
        Section(header: Text("Review").titleStyle()) {
            Text("""
Review the processed csv data and confirm the import of the following objects.
""").padding(.top, 8)
            HStack {
                Text("Ranges:")
                Spacer()
                Text("\(self.importer.wrappedValue?.ranges ?? 0)")
            }
            HStack {
                Text("Events:")
                Spacer()
                Text("\(self.importer.wrappedValue?.events ?? 0)")
            }
            HStack {
                Text("Total records:")
                Spacer()
                Text("\(self.importer.wrappedValue?.entries ?? 0)")
            }
            HStack {
                Text("Total root categories:")
                Spacer()
                Text("\(self.importer.wrappedValue?.rootCategories?.count ?? 0)")
            }
            
            Button("Import data") {
                Time.shared.store.importData(from: self.importer.wrappedValue!) { (importedRequest, error) in
                    guard error == nil else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.show = false
                    }
                }
            }.disabled(self.importer.wrappedValue == nil)
        }
    }
}

fileprivate struct ImportDocumentPicker: UIViewControllerRepresentable {
    @Binding var url: URL?
    
    func makeCoordinator() -> ImportDocumentPickerCoordinator {
        return ImportDocumentPickerCoordinator(url: $url)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImportDocumentPicker>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.plainText], asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }
}

fileprivate class ImportDocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    @Binding var url: URL?
    
    init(url: Binding<URL?>) {
        _url = url
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.url = urls[0]
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}


#if DEBUG
struct ImportWizard_Previews: PreviewProvider {
    static var previews: some View {
        let show = Binding<Bool>(
            get: { return true },
            set: { _ in }
        )
        
        ImportWizard(show: show)
    }
}
#endif
