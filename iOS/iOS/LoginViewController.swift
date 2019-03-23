//
//  LoginViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 3/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var logInButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.emailTextField.placeholder = NSLocalizedString("Email", comment: "")
        self.emailTextField.keyboardType = .emailAddress
        self.emailTextField.autocapitalizationType = .none
        
        self.passwordTextField.placeholder = NSLocalizedString("Password", comment: "")
        self.passwordTextField.spellCheckingType = .no
        self.passwordTextField.autocapitalizationType = .none
        self.passwordTextField.isSecureTextEntry = true
        
        self.signUpButton.setTitle(NSLocalizedString("Sign Up", comment: ""), for: .normal)
        self.logInButton.setTitle(NSLocalizedString("Log In", comment: ""), for: .normal)
    }
    
    @IBAction func handleButtonPress(_ sender: UIButton) {
        guard let email = self.emailTextField.text else {
            // Show Error
            return
        }
        guard let password = self.passwordTextField.text else {
            // Show Error
            return
        }
        guard email.count > 0 && password.count > 0 else {
            // Show Error
            return
        }
        
        let signUp = sender == self.signUpButton
        if signUp {
            // Validate email and password
        }
        
        if signUp {
            // Not supported
        } else {
            Time.shared.authenticate(username: email, password: password) { error in
                guard error == nil else {
                    // Show Error
                    return
                }
                
                self.showHome()
            }
        }
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        self.view.endEditing(false)
    }
    
    func showHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "homeView")
        let action = { self.present(controller, animated: true, completion: nil) }
        
        if Thread.isMainThread { action() }
        else { DispatchQueue.main.async { action() }}
    }
}
