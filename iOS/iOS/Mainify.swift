//
//  Mainify.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/10/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation

func Mainify(block: @escaping () -> ()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
