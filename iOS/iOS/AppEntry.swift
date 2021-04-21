//
//  AppEntry.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import TimeSDK
import SwiftUI
import WidgetKit

@main
struct AppEntry: App {
    @Environment(\.scenePhase) var scenePhase
    
    @State var initialized: Bool = false
    @State var authenticated: Bool = false
    
    @State var showInternetAlert: Bool = false
    
    init() {
        // Read from app container (to pull from iOS system settings)
        let appContainerServerURLKey = "server_url_override"
        let appContainerServerURLOverride = UserDefaults().string(forKey: appContainerServerURLKey)
        
        // Write to shared container to share with app extensions
        let sharedUserDefaults = UserDefaults(suiteName: Constants.userDefaultsSuite)
        if let override = appContainerServerURLOverride, let userDefaults = sharedUserDefaults {
            userDefaults.set(override, forKey: Constants.urlOverrideKey)
        }
        
        // Read from shared container (unneeded, but will allow following code to match Widget)
        let serverURLOverride = sharedUserDefaults?.string(forKey: Constants.urlOverrideKey)
        
        let config = TimeConfig(
            serverURL: serverURLOverride,
            containerURL: Constants.containerUrl,
            userDefaultsSuite: Constants.userDefaultsSuite,
            keychainGroup: Constants.keychainGroup
        )
        
        Time.configureShared(config)
    }
    
    var body: some Scene {
        WindowGroup {
            if !initialized {
                VStack {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
            } else if !authenticated {
                Login(authenticated: $authenticated).environmentObject(Warehouse.shared)
            } else {
                Home(signOut: {
                    Warehouse.shared.time?.deauthenticate()
                    self.authenticated = false
                }).environmentObject(Warehouse.shared)
                .onReceive(.TimeUserSignInNeeded) { (_) in
                    self.authenticated = false
                }
                .onReceive(.TimeUnableToReachServer) { (_) in
                    self.showInternetAlert = true
                }
                .alert(isPresented: $showInternetAlert, content: {
                    Alert(
                        title: Text("Network Error"),
                        message: Text("The requested action requires a valid network connection. Please verify your internet connection and try again."),
                        dismissButton: .default(Text("OK"))
                    )
                })
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                // Back to foreground
                if !initialized {
                    Time.shared.initialize() { error in
                        // Force to main thread and run at end of current view updates
                        DispatchQueue.main.async {
                            self.initialized = true
                            self.authenticated = error == nil
                        }
                    }
                } else {
                    Time.shared.store.fetchRemoteChanges()
                }
            case .inactive:
                // Entering background
                WidgetCenter.shared.reloadAllTimelines()
            case .background:
                // In background
                break
            @unknown default:
                break
            }
        }
    }
}
