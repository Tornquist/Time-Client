//
//  TextModal.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct TextModal<Content: View>: View {
    var title: String
    var description: Content
    
    var placeholder: String
    
    @Binding var show: Bool
    @State var value: String = ""
    
    var onSave: ((String) -> ())? = nil
        
    var body: some View {
        NavigationView {
            Form {
                Section(header: description, content: {
                    TextField(placeholder, text: $value)
                })
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        show = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave?(value)
                    }.disabled(value == "")
                }
            }
        }
    }
}

#if DEBUG
struct TextModal_Previews: PreviewProvider {
    @State static var show: Bool = true
    
    static var previews: some View {
        let categoryName = "Time"
        
        return TextModal(
            title: "Rename",
            description: Text("Enter a new name for ") + Text(categoryName).fontWeight(.black),
            placeholder: "New name",
            show: $show
        )
            .environment(\.colorScheme, .dark)
    }
}
#endif
