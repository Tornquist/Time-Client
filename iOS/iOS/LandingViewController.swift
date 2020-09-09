//
//  LandingViewController.swift
//  Time-iOS
//
//  Created by Nathan Tornquist on 12/9/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class LandingViewController: UIViewController {

    // Direction Flags
    var initialized: Bool = false
    var authenticated: Bool = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        Time.shared.initialize() { error in
            self.initialized = true
            self.authenticated = error == nil
            self.handleTransition()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.handleTransition()
    }
    
    func handleTransition() {
        let viewLoaded = self.viewIfLoaded?.window != nil
        
        guard viewLoaded && self.initialized else { return }
        
        let action = {
            if self.authenticated {
                let controller = self.buildApp()
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: false, completion: nil)
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "loginView")
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: false, completion: nil)
            }
        }
        
        if Thread.isMainThread { action() }
        else { DispatchQueue.main.async { action() } }
    }
    
    func buildApp() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let categoriesVC = storyboard.instantiateViewController(withIdentifier: "categoriesView")
        let categoriesNavVC = HomeViewController(rootViewController: categoriesVC)

        return categoriesNavVC
    }
}
