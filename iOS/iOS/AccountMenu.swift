//
//  AccountMenu.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/13/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct AccountMenu: View {
    var root: TimeSDK.Category
    var selected: ((TimeSDK.Category, Selection) -> Void)? = nil
    
    enum Selection: Identifiable {
        case addChild
        case rename

        var id: Int { hashValue }
    }
    
    var body: some View {
        Menu {
            Button(action: {
                self.selected?(root, .addChild)
            }, label: {
                Label("Add Child", systemImage: "plus")
            })
//            Button(action: {
//                self.selected?(root, .rename)
//            }, label: {
//                Label("Rename", systemImage: "text.cursor")
//            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
                .frame(width: 16, height: 16, alignment: .center)
        }
    }
}
