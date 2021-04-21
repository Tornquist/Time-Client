//
//  Text+.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/6/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

extension Text {
    func titleStyle() -> some View {
        self
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(Color(.label))
            .textCase(.none)
    }
}
