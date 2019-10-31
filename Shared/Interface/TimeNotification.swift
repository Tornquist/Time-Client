//
//  TimeNotification.swift
//  Shared
//
//  Created by Nathan Tornquist on 9/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let TimeAPIAutoRefreshedToken = Notification.Name("TimeAPIAutoRefreshedToken")
    static let TimeAPIAutoRefreshFailed = Notification.Name("TimeAPIAutoRefreshFailed")
    
    public static let TimeUserSignInNeeded = Notification.Name("TimeUserSignInNeeded")
    public static let TimeUnableToReachServer = Notification.Name("TimeUnableToReachServer")
}
