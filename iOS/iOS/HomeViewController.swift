//
//  HomeViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 9/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit

class HomeViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showReauthentication), name: .TimeUserSignInNeeded, object: nil)
    }
    
    @objc func showReauthentication() {
        let showVC = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "loginView")
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
}
