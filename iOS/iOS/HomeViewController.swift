//
//  HomeViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 3/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class HomeViewController: UIViewController {
    
    @IBOutlet weak var signOutButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.signOutButton.setTitle(NSLocalizedString("Sign Out", comment: ""), for: .normal)
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        Time.shared.deauthenticate()
        self.dismiss(animated: true, completion: nil)
    }
}
