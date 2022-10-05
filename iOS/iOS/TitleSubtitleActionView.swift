//
//  TitleSubtitleActionView.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/3/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct TitleSubtitleActionView: View {
    var title: String
    var subtitle: String
    var action: Action
    var active: Bool
    var loading: Bool
    var onTapText: (() -> ())? = nil
    var onTapButton: (() -> ())? = nil
    
    enum Action {
        case play
        case pause
        case stop
        case record
        case none
        
        var icon: String? {
            switch self {
            case .play: return "play.circle"
            case .pause: return "pause.circle"
            case .record: return "smallcircle.fill.circle"
            case .stop: return "stop.circle"
            case .none: return nil
            }
        }
    }
    
    var body: some View {
        HStack {
            HStack {
                VStack(alignment: .leading, spacing: 8, content: {
                    Text(title)
                        .font(Font.system(size: 17.0))
                        .foregroundColor(self.active ? Color(Colors.active) : Color(.label))
                    Text(subtitle)
                        .font(Font.system(size: 12.0))
                        .foregroundColor(Color(.label))
                })
                Spacer()
            }
            .onTapGesture {
                onTapText?()
            }
            Spacer()
            if loading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            } else if action != .none {
                VStack {
                    Spacer()
                    Button(action: {
                        onTapButton?()
                    }) {
                        Text(Image(systemName: self.action.icon ?? "questionmark"))
                            .imageScale(.large)
                            .font(Font.system(size: 16.0))
                            .foregroundColor(Color(Colors.button))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Spacer()
                }
            }
        }
    }
}


#if DEBUG
struct TitleSubtitleActionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TitleSubtitleActionView(title: "Time", subtitle: "Side Projects", action: .pause, active: true, loading: true)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Active Light")
            
            TitleSubtitleActionView(title: "Time", subtitle: "Side Projects", action: .play, active: false, loading: false)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Inactive Light")
            
            TitleSubtitleActionView(title: "Time", subtitle: "Side Projects", action: .pause, active: true, loading: true)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Active Dark")
                .environment(\.colorScheme, .dark)
            
            TitleSubtitleActionView(title: "Time", subtitle: "Side Projects", action: .play, active: false, loading: false)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Inactive Dark")
                .environment(\.colorScheme, .dark)
            
            TitleSubtitleActionView(title: "Side Projects > Time", subtitle: "02/15/21 08:09 PM CST - Present", action: .stop, active: true, loading: false)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Open Entry")
                .environment(\.colorScheme, .dark)
            
            TitleSubtitleActionView(title: "Side Projects > Time", subtitle: "02/15/21 02:09 PM CST - 06:19 CST", action: .none, active: false, loading: false)
                .background(Color(.secondarySystemGroupedBackground))
                .previewLayout(.fixed(width: 375, height: 75))
                .previewDisplayName("Closed Entry")
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
