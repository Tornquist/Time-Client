//
//  QuantityMetric.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/3/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

struct QuantityMetric: View {
    var total: String
    var description: String
    var items: [QuantityItem]
    
    var someActive: Bool {
        return items.reduce(false, { $0 || $1.active })
    }
    
    struct QuantityItem {
        var name: String
        var total: String
        var active: Bool
    }
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(total)
                        .font(Font.system(size: 34.0).monospacedDigit())
                        .foregroundColor(someActive ? Color(Colors.active) : Color(.label))
                    Spacer()
                }
                HStack {
                    Text(description)
                        .font(Font.system(size: 12.0))
                    Spacer()
                }
                Spacer()
            }
            .padding(.trailing, 4)
            VStack {
                ForEach(items, id: \.name) { (item) in
                    HStack {
                        Text(item.name)
                            .font(Font.system(size: 12.0))
                        Spacer()
                        Text(item.total)
                            .font(Font.system(size: 12.0).monospacedDigit())
                    }
                    .foregroundColor(item.active ? Color(Colors.active) : Color(.label))
                }
                Spacer()
            }
        }.padding(.all, 16)
    }
}

#if DEBUG
struct QuantityMetric_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuantityMetric(
                total: "27:71:04",
                description: "This Week",
                items: [
                    QuantityMetric.QuantityItem(
                        name: "Project 1",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 2",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 3",
                        total: "03:46:11",
                        active: true
                    )
                ]
            )
            .background(Color(.secondarySystemGroupedBackground))
            .previewLayout(.fixed(width: 375, height: 95.33))
            .previewDisplayName("Normal List")
            
            QuantityMetric(
                total: "27:71:04",
                description: "This Week",
                items: [
                    QuantityMetric.QuantityItem(
                        name: "Project 1",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 2",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 3",
                        total: "03:46:11",
                        active: true
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 4",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 5",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Project 6",
                        total: "03:46:11",
                        active: false
                    )
                ]
            )
            .background(Color(.secondarySystemGroupedBackground))
            .previewLayout(.fixed(width: 375, height: 130))
            .previewDisplayName("Long List")
            .environment(\.colorScheme, .dark)
            
            QuantityMetric(
                total: "27:71:04",
                description: "This Week",
                items: [
                    QuantityMetric.QuantityItem(
                        name: "Normal 1",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Really long project name",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        name: "Normal 2",
                        total: "23:46:55",
                        active: false
                    ),
                ]
            )
            .background(Color(.secondarySystemGroupedBackground))
            .previewLayout(.fixed(width: 375, height: 95.33))
            .previewDisplayName("Long Name")
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
