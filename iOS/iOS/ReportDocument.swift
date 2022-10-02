//
//  ReportDocument.swift
//  iOS
//
//  Created by Nathan Tornquist on 10/2/22.
//  Copyright © 2022 nathantornquist. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI // For FileDocument

struct ReportDocument: FileDocument {
    
    static var readableContentTypes: [UTType] { [.plainText] }

    var message: String

    init(message: String) {
        self.message = message
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        message = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: message.data(using: .utf8)!)
    }
}
