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
        
        Time.shared.initialize { error in
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
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewName = self.authenticated ? "homeView" : "loginView"
            let controller = storyboard.instantiateViewController(withIdentifier: viewName)
            self.present(controller, animated: false, completion: nil)
        }
        
        if Thread.isMainThread { action() }
        else { DispatchQueue.main.async { action() } }
    }
}
