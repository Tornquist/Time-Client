//
//  Binding+onChange.swift
//  iOS
//
//  Created by Nathan Tornquist on 3/20/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
