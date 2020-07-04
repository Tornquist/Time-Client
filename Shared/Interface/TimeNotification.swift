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
    
    public static let TimeCategoryArchiveRequested = Notification.Name("TimeCategoryArchiveRequested")
    
    public static let TimeUserSignInNeeded = Notification.Name("TimeUserSignInNeeded")
    public static let TimeUnableToReachServer = Notification.Name("TimeUnableToReachServer")
    
    public static let TimeImportRequestCreated = Notification.Name("TimeImportRequestCreated")
    public static let TimeImportRequestCompleted = Notification.Name("TimeImportRequestCompleted")
    
    public static let TimeBackgroundStoreUpdate = Notification.Name("TimeBackgroundStoreUpdate")
    
    public static let TimeEntryStarted = Notification.Name("TimeEntryStarted")
    public static let TimeEntryStopped = Notification.Name("TimeEntryStopped")
    public static let TimeEntryRecorded = Notification.Name("TimeEntryRecorded")
    public static let TimeEntryModified = Notification.Name("TimeEntryModified")
    public static let TimeEntryDeleted = Notification.Name("TimeEntryDeleted")
}
