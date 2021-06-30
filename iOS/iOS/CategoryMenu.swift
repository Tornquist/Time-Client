//
//  CategoryMenu.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/13/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct CategoryMenu: View {
    var category: TimeSDK.Category
    var isRunning: Bool
    var selected: ((TimeSDK.Category, Selection) -> Void)? = nil
    
    enum Selection: Identifiable {
        case addChild
        case move
        case rename
        case delete
        case toggleState
        case recordEvent

        var id: Int { hashValue }
    }
    
    var body: some View {
        Menu {
            Menu {
                Button(role: .destructive, action: {
                    self.selected?(category, .delete)
                }, label: {
                    Label("Delete", systemImage: "trash")
                })
                Button(action: {
                    self.selected?(category, .rename)
                }, label: {
                    Label("Rename", systemImage: "text.cursor")
                })
                Button(action: {
                    self.selected?(category, .move)
                }, label: {
                    Label("Move", systemImage: "arrow.up.and.down")
                })
                Button(action: {
                    self.selected?(category, .addChild)
                }, label: {
                    Label("Add Child", systemImage: "plus")
                })
            } label: {
                Label("Modify", systemImage: "gear")
            }
            Button(action: {
                self.selected?(category, .recordEvent)
            }, label: {
                Label("Record", systemImage: "smallcircle.fill.circle")
            })
            Button(action: {
                self.selected?(category, .toggleState)
            }, label: {
                Label(isRunning ? "Stop" : "Start", systemImage: isRunning ? "pause.circle" : "play.circle")
            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
                .frame(width: 16, height: 16, alignment: .center)
        }
    }
}
