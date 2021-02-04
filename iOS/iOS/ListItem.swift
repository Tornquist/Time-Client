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
    var level: Int = -1
    var open: Bool = false
    var showIcon: Bool = true
    
    let borderWidth: CGFloat = 16.0
    let baseOffset: CGFloat = 12.0
    let imageSize: CGFloat = 16.0
    let imageIconSpace: CGFloat = 12.0
    
    var leadingSpace: CGFloat {
        guard level >= 0 else {
            return borderWidth
        }
        
        let adjustedLevel = CGFloat(showIcon ? level : level + 1)
        
        return baseOffset + (imageSize + imageIconSpace) * adjustedLevel
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: self.leadingSpace)
            if showIcon && level >= 0 {
                Image(systemName: open ? "chevron.down" : "chevron.right")
                    .font(Font.system(size: 16.0, weight: .semibold))
                    .foregroundColor(Color(Colors.button))
                    .frame(width: imageSize, height: imageSize, alignment: .center)
                Spacer(minLength: imageIconSpace)
            }
            Text(text)
                .font(Font.system(size: 15.0))
                .layoutPriority(2)
            Spacer()
                .layoutPriority(1)
        }
        .padding([.leading], 0)
        .padding([.trailing, .top, .bottom], borderWidth)
    }
}

#if DEBUG
struct ListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 0) {
                ListItem(text: "Account 1")
                ListItem(text: "Side Projects", level: 0, open: true)
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
