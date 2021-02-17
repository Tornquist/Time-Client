//
//  ImportList.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/17/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct ImportList: View {
    
    @ObservedObject var model: ImportModel
    var show: Binding<Bool>
    
    let dateFormatter: DateFormatter
    
    init(model: ImportModel, show: Binding<Bool>) {
        self.model = model
        self.show = show
        
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yy"
    }
    
    var body: some View {
        NavigationView {
            List(model.requests, id: \.id) { request in
                HStack {
                    HStack {
                        Spacer(minLength: 0)
                        Text(self.dateFormatter.string(from: request.createdAt))
                            .font(Font.system(.body).monospacedDigit())
                    }.frame(width: 75)
                    HStack {
                        Text(request.complete ? "Complete" : "Processing")
                            .font(Font.system(.body))
                            .layoutPriority(1)
                        Spacer()
                            .layoutPriority(1)
                    }
                }
            }.navigationTitle("Imports")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        self.show.wrappedValue = false
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ImportList_Previews: PreviewProvider {
    @State static var show: Bool = true
    
    static var previews: some View {
        let warehouse = Warehouse.getPreviewWarehouse()
        let model = ImportModel(for: warehouse)
        model.requests = [
            FileImporter.Request(
                id: 1,
                createdAt: Date(timeIntervalSince1970: 1612569118112),
                updatedAt: Date(timeIntervalSince1970: 1612569118112),
                categories: FileImporter.Request.Status(imported: 3, expected: 3),
                entries: FileImporter.Request.Status(imported: 3123, expected: 3123),
                complete: true,
                success: true
            ),
            FileImporter.Request(
                id: 2,
                createdAt: Date(timeIntervalSince1970: 1613569118112),
                updatedAt: Date(timeIntervalSince1970: 1613569118112),
                categories: FileImporter.Request.Status(imported: 1, expected: 3),
                entries: FileImporter.Request.Status(imported: 1354, expected: 3123),
                complete: false,
                success: false
            )
        ]
        
        let show = Binding<Bool>(
            get: { return true },
            set: { _ in }
        )
        
        return ImportList(model: model, show: show)
            .environmentObject(warehouse)
//            .environment(\.colorScheme, .dark)
    }
}
#endif
