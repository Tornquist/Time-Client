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
    @State var showFilePicker: Bool = false
    
    @State var url: URL? = nil
    @State var delimiter: String = ","
    @State var importer: FileImporter? = nil
    
    @State var loadingData: Bool = false
    
    @State var step: Step = .welcome
    
    enum Step {
        case welcome
        case loadFile
        case configureParsing
    }
    
    var body: some View {
        NavigationView {
            Form {
                if step == .welcome {
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
                
                if step == .loadFile {
                    Section(header: Text("Select file").titleStyle()) {
                        Button(self.url != nil ? url!.lastPathComponent : "Choose file") {
                            self.showFilePicker = true
                        }
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
                                TextField("Delimiter", text: $delimiter)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    if self.url != nil && self.delimiter.count == 1 {
                        Section(header: Text("Load data").titleStyle()) {
                            Text("Attempt to load the data from the provided file with the provided delimiter.").padding(.top, 8)
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
                                            self.importer = importer
                                            self.loadingData = false
                                        }
                                    } catch {
                                        // TODO: Handle error
                                        DispatchQueue.main.async {
                                            self.loadingData = false
                                        }
                                    }
                                }
                            }, label: {
                                Text("Load Data")
                            }).disabled(self.loadingData)
                        }
                    }
                    
                    if self.importer != nil {
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
                                        Text("\(self.importer!.columns?.count ?? 0)")
                                        Spacer()
                                    }
                                    HStack {
                                        Text("\(self.importer!.rows ?? 0)")
                                        Spacer()
                                    }
                                }
                            }
                            Button(action: {
                                self.step = .configureParsing
                            }, label: {
                                Text("Continue")
                            })
                        }
                    }
                }
                
                if self.step == .configureParsing {
                    Section(header: Text("Identify tree")) {
                        
                    }
                    
                    Section(header: Text("Specify date format")) {
                        
                    }
                    
                    Section(header: Text("Review")) {
                        
                    }
                }
            }.navigationTitle("Import Wizard")
            .sheet(isPresented: $showFilePicker, content: {
                ImportDocumentPicker(url: $url)
            })
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

struct ImportDocumentPicker: UIViewControllerRepresentable {
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

class ImportDocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
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
