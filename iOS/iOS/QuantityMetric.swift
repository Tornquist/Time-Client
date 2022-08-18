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
        var id: Int
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
                }.padding(.bottom, 2)
                HStack {
                    Text(description)
                        .font(Font.system(size: 12.0))
                    Spacer()
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 4)
            VStack {
                ForEach(items, id: \.id) { (item) in
                    HStack {
                        Text(item.name)
                            .font(Font.system(size: 12.0))
                        Spacer()
                        Text(item.total)
                            .font(Font.system(size: 12.0).monospacedDigit())
                    }
                    .foregroundColor(item.active ? Color(Colors.active) : Color(.label))
                }
                Spacer(minLength: 0)
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
                        id: 1,
                        name: "Project 1",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 2,
                        name: "Project 2",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 3,
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
                        id: 1,
                        name: "Project 1",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 2,
                        name: "Project 2",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 3,
                        name: "Project 3",
                        total: "03:46:11",
                        active: true
                    ),
                    QuantityMetric.QuantityItem(
                        id: 4,
                        name: "Project 4",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 5,
                        name: "Project 5",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 6,
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
                        id: 1,
                        name: "Normal 1",
                        total: "23:46:55",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 2,
                        name: "Really long project name",
                        total: "00:19:27",
                        active: false
                    ),
                    QuantityMetric.QuantityItem(
                        id: 3,
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
