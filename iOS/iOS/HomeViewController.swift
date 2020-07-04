//
//  HomeViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 9/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit

class HomeViewController: UINavigationController {
    
    var showingNetworkError: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showReauthentication), name: .TimeUserSignInNeeded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unableToReachServer), name: .TimeUnableToReachServer, object: nil)
        
        self.navigationBar.prefersLargeTitles = true
    }
    
    @objc func showReauthentication() {
        let showVC = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "loginView")
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }

        if Thread.isMainThread {
            showVC()
        } else {
            DispatchQueue.main.async {
                showVC()
            }
        }
    }
    
    @objc func unableToReachServer() {
        guard !self.showingNetworkError else { return }
        self.showingNetworkError = true
        
        let showAlert = {
            let title = NSLocalizedString("Network Error", comment: "")
            let message = NSLocalizedString("The requested action requires a valid network connection. Please verify your internet connection and try again.", comment: "")
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (_) in
                self.showingNetworkError = false
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        if Thread.isMainThread {
            showAlert()
        } else {
            DispatchQueue.main.async {
                showAlert()
            }
        }
    }
}
