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
        case configureParsing
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
                 
                if self.step == .configureParsing {
                    Section(header: Text("Specify date format")) {
                        
                    }
                    
                    Section(header: Text("Review")) {
                        
                    }
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
                    Text("Load Data")
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
                    self.step = .configureParsing
                }, label: {
                    Text("Continue")
                }).disabled(self.treeColumns.count == 0)
            }
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
