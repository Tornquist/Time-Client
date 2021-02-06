//
//  ListItem.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/3/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct ListItem<Content : View>: View {
    
    let text: String
    let level: Int
    let open: Bool
    let showIcon: Bool
    
    let trailingView: () -> Content
    
    let borderWidth: CGFloat = 16.0
    let baseOffset: CGFloat = 12.0
    let imageSize: CGFloat = 16.0
    let imageIconSpace: CGFloat = 12.0
        
    var animation: Animation {
        Animation.easeOut
    }
        
    var leadingSpace: CGFloat {
        guard level >= 0 else {
            return borderWidth
        }
        
        let adjustedLevel = CGFloat(showIcon ? level : level + 1)
        
        return baseOffset + (imageSize + imageIconSpace) * adjustedLevel
    }
    
    init(
        text: String,
        level: Int = -1,
        open: Bool = false,
        showIcon: Bool = true,
        tapped: (() -> ())? = nil,
        @ViewBuilder trailingView: @escaping () -> Content
    ) {
        self.text = text
        self.level = level
        self.open = open
        self.showIcon = showIcon
        self.trailingView = trailingView
    }
    
    // Alternative init to allow trailingView to be dropped completely
    init(
        text: String,
        level: Int = -1,
        open: Bool = false,
        showIcon: Bool = true,
        tapped: (() -> ())? = nil
    ) where Content == EmptyView {
        self.init(
            text: text,
            level: level,
            open: open,
            showIcon: showIcon,
            tapped: tapped,
            trailingView: { })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: self.leadingSpace)
            if showIcon && level >= 0 {
                Image(systemName: "chevron.right")
                    .font(Font.system(size: 12.0, weight: .semibold))
                    .foregroundColor(Color(Colors.button))
                    .frame(width: imageSize, height: imageSize, alignment: .center)
                    .rotationEffect(Angle.degrees(open ? 90 : 0))
                    .animation(animation)
                Spacer(minLength: imageIconSpace)
            }
            Text(text)
                .font(Font.system(size: 15.0))
                .layoutPriority(2)
            Spacer()
                .layoutPriority(1)
            trailingView()
        }
        .padding([.leading], 0)
        .padding([.trailing, .top, .bottom], borderWidth)
        .contentShape(Rectangle())
    }
}

#if DEBUG
struct ListItem_Previews: PreviewProvider {
    static func accountMenu() -> some View {
        Menu {
            Button(action: {  }, label: {
                Label("Rename", systemImage: "text.cursor")
            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
        }
    }
    
    static func categoryMenu() -> some View {
        Menu {
            Menu {
                Button(action: {  }, label: {
                    Label("Add Child", systemImage: "plus")
                })
                Button(action: {  }, label: {
                    Label("Move", systemImage: "arrow.up.and.down")
                })
                Button(action: {  }, label: {
                    Label("Rename", systemImage: "text.cursor")
                })
                Button(action: {  }, label: {
                    Label("Delete", systemImage: "trash")
                })
            } label: {
                Label("Modify", systemImage: "gear")
            }
            Button(action: {  }, label: {
                Label("Start", systemImage: "play.circle")
            })
            Button(action: {  }, label: {
                Label("Record", systemImage: "smallcircle.fill.circle")
            })
        } label: {
            Image(systemName: "ellipsis")
                .font(Font.system(size: 12.0, weight: .semibold))
                .foregroundColor(Color(Colors.button))
        }
    }
    
    static var previews: some View {
        Group {
            VStack(spacing: 0) {
                ListItem(text: "Account 1")
                ListItem(text: "Account 1") { }
                ListItem(text: "Account 1", trailingView: { })
            }
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 150))
                .previewDisplayName("Empty Init Options")
            
            VStack(spacing: 0) {
                ListItem(text: "Account 1") {
                    accountMenu()
                }
                ListItem(text: "Side Projects", level: 0, open: true) {
                    categoryMenu()
                }
                ListItem(text: "Time", level: 1, open: true) {
                    categoryMenu()
                }
                ListItem(text: "Fixes", level: 2, open: false) {
                    categoryMenu()
                }
            }
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 200))
                .previewDisplayName("Basic Tree")
                .environment(\.colorScheme, .dark)
            
            VStack(spacing: 0) {
                ListItem(text: "More", level: 0, open: true)
                ListItem(text: "Add Account", level: 0, open: true, showIcon: false)
                ListItem(text: "Import Records", level: 0, open: false, showIcon: false)
                ListItem(text: "Sign Out", level: 0, open: false, showIcon: false)
            }
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 200))
                .previewDisplayName("More")
        }
    }
}
#endif
