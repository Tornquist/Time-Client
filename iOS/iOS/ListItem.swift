//
//  ListItem.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/3/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct ListItem: View {
    
    var text: String
    var level: Int
    var open: Bool
    var showIcon: Bool
    
    let borderWidth: CGFloat = 16.0
    let baseOffset: CGFloat = 12.0
    let imageSize: CGFloat = 16.0
    let imageIconSpace: CGFloat = 12.0
    
    var tapped: (() -> ())? = nil
    var actions: [Action] = []
    
    struct Action {
        var title: String
        var icon: String? = nil
        var destructive: Bool = false
        var action: (() -> ())? = nil
        var children: [Action] = []
    }
    
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
    
    init(text: String, level: Int = -1, open: Bool = false, showIcon: Bool = true, tapped: (() -> ())? = nil, actions: [Action] = []) {
        self.text = text
        self.level = level
        self.open = open
        self.showIcon = showIcon
        self.tapped = tapped
        self.actions = actions
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
            if actions.count > 0 {
                Menu {
                    ForEach(actions, id: \.title) { (action) in
                        if action.children.count == 0 {
                            Button(action: { action.action?() }, label: {
                                Label(action.title, systemImage: action.icon ?? "")
                            })
                        } else {
                            Menu {
                                ForEach(action.children, id: \.title) { (child) in
                                    Button(action: { child.action?() }, label: {
                                        Label(child.title, systemImage: child.icon ?? "")
                                    })
                                }
                            } label: {
                                Label(action.title, systemImage: action.icon ?? "")
                                
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(Font.system(size: 12.0, weight: .semibold))
                        .foregroundColor(Color(Colors.button))
                }
            }
        }
        .padding([.leading], 0)
        .padding([.trailing, .top, .bottom], borderWidth)
        .contentShape(Rectangle())
        .onTapGesture {
            self.tapped?()
        }
    }
}

#if DEBUG
struct ListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 0) {
                ListItem(text: "Account 1")
                ListItem(text: "Side Projects", level: 0, open: true, actions: [
                    ListItem.Action(title: "Modify", icon: "gear", children: [
                        ListItem.Action(title: "Add Child", icon: "plus"),
                        ListItem.Action(title: "Move", icon: "arrow.up.and.down", destructive: true),
                        ListItem.Action(title: "Rename", icon: "text.cursor"),
                        ListItem.Action(title: "Delete", icon: "trash")
                    ]),
                    ListItem.Action(title: "Record", icon: "smallcircle.fill.circle"),
                    ListItem.Action(title: "Start", icon: "play.circle")
                ])
                ListItem(text: "Time", level: 1, open: true)
                ListItem(text: "Fixes", level: 2, open: false)
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
