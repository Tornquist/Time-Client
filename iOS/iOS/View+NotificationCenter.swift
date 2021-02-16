//
//  NotificationCenter.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    func onReceive(_ name: Notification.Name,
                   center: NotificationCenter = .default,
                   object: AnyObject? = nil,
                   perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(
            center.publisher(for: name, object: object), perform: action
        )
    }
}
