//
//  ViewController.swift
//  Time-macOS
//
//  Created by Nathan Tornquist on 12/9/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Cocoa
import TimeSDK

class LoginViewController: NSViewController {

    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        Time.shared.initialize { error in
            if error == nil { self.openApplication() }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func loginTapped(_ sender: NSButton) {
        loginUser()
    }
    
    // MARK: - Data Management
    
    func loginUser() {
        let email = self.emailTextField.stringValue
        let password = self.passwordTextField.stringValue
        Time.shared.authenticate(email: email, password: password) { error in
            if error == nil {
                self.openApplication()
            }
        }
    }
    
    func openApplication() {
        let action = {
            self.performSegue(withIdentifier: "login", sender: nil)
        }
        
        let isMain = Thread.main.isMainThread
        if isMain { action() }
        else { DispatchQueue.main.async { action() } }
    }
}
