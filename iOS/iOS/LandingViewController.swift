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
                
        let serverURLOverride = UserDefaults.standard.string(forKey: "server_url_override")
        Time.shared.initialize(for: serverURLOverride) { error in
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
                let controller = self.buildTabBarController()
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
    
    func buildTabBarController() -> UIViewController {
        let tabBarVC = HomeViewController()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let categoriesVC = storyboard.instantiateViewController(withIdentifier: "categoriesView")
        let entriesVC = storyboard.instantiateViewController(withIdentifier: "entriesView")
        
        let categoriesNavVC = UINavigationController(rootViewController: categoriesVC)
        let entriesNavVC = UINavigationController(rootViewController: entriesVC)
        
        categoriesNavVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Categories", comment: ""),
            image: UIImage(named: "icon_categories"),
            selectedImage: UIImage(named: "icon_categories_selected")
        )
        
        entriesNavVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Entries", comment: ""),
            image: UIImage(named: "icon_entries"),
            selectedImage: UIImage(named: "icon_entries_selected")
        )
        
        tabBarVC.setViewControllers([categoriesNavVC, entriesNavVC], animated: false)
        
        return tabBarVC
    }
}
