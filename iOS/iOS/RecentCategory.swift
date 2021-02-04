//
//  RecentCategory.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/3/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct RecentCategory: View {
    var name: String
    var parents: String
    var action: Action
    var active: Bool
    
    enum Action {
        case play
        case pause
        case record
        
        var icon: String {
            switch self {
            case .play: return "play.circle"
            case .pause: return "pause.circle"
            case .record: return "smallcircle.fill.circle"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 8, content: {
                HStack {
                    Text(name)
                        .font(Font.system(size: 17.0))
                        .foregroundColor(self.active ? Color(Colors.active) : Color(.label))
                    Spacer()
                }
                HStack {
                    Text(parents)
                        .font(Font.system(size: 12.0))
                        .foregroundColor(self.active ? Color(Colors.active) : Color(.label))
                    Spacer()
                }
            })
            Spacer()
            VStack {
                Spacer()
                Button(action: {
                  print("button pressed")
                }) {
                    Image(systemName: self.action.icon)
                        .imageScale(.large)
                        .foregroundColor(Color(Colors.button))
                }
                Spacer()
            }
        }.padding(.all, 16)
    }
}

#if DEBUG
struct RecentCategory_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RecentCategory(name: "Time", parents: "Side Projects", action: .pause, active: true)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Active Light")
            
            RecentCategory(name: "Time", parents: "Side Projects", action: .play, active: false)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Inactive Light")
            
            RecentCategory(name: "Time", parents: "Side Projects", action: .pause, active: true)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Active Dark")
                .environment(\.colorScheme, .dark)
            
            RecentCategory(name: "Time", parents: "Side Projects", action: .play, active: false)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Inactive Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
