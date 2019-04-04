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
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.emailTextField.placeholder = NSLocalizedString("Email", comment: "")
        self.emailTextField.spellCheckingType = .no
        self.emailTextField.keyboardType = .emailAddress
        self.emailTextField.autocapitalizationType = .none
        self.emailTextField.autocorrectionType = .no
        
        self.passwordTextField.placeholder = NSLocalizedString("Password", comment: "")
        self.passwordTextField.spellCheckingType = .no
        self.passwordTextField.autocapitalizationType = .none
        self.passwordTextField.isSecureTextEntry = true
        
        self.signUpButton.setTitle(NSLocalizedString("Sign Up", comment: ""), for: .normal)
        self.logInButton.setTitle(NSLocalizedString("Log In", comment: ""), for: .normal)
        
        self.errorLabel.text = nil
        self.errorLabel.font = UIFont.systemFont(ofSize: 12.0)
    }
    
    @IBAction func handleButtonPress(_ sender: UIButton) {
        self.hideError()
        
        guard
            let email = self.emailTextField.text,
            let password = self.passwordTextField.text,
            email.count > 0 && password.count > 0
            else {
                // Show Error
                self.show(error: NSLocalizedString("Email and password are required", comment: ""))
                return
        }
        
        let signUp = sender == self.signUpButton
        if signUp {
            // Validate email and password
            let emailRange = NSRange(location: 0, length: email.utf16.count)
            let emailRegex = try! NSRegularExpression(pattern: "^(([^<>()\\[\\]\\\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\\\.,;:\\s@\"]+)*)|(\".+\"))@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}])|(([a-zA-Z\\-0-9]+\\.)+[a-zA-Z]{2,}))$")
            let validEmail = emailRegex.firstMatch(in: email, options: [], range: emailRange) != nil
            
            let passwordRange = NSRange(location: 0, length: password.utf16.count)
            let passwordRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9@*#!%$_-]{8,30})$")
            let validPassword = passwordRegex.firstMatch(in: password, options: [], range: passwordRange) != nil
            
            if !validEmail || !validPassword {
                var errorComponents: [String] = []
                if !validEmail {
                    errorComponents.append(NSLocalizedString("Invalid email", comment: ""))
                }
                if !validPassword {
                    errorComponents.append(NSLocalizedString("Invalid password", comment: ""))
                }
                let error = errorComponents.joined(separator: "\n")
                self.show(error: error)
                return
            }
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
    
    @IBAction func editingChanged(_ sender: Any) {
        self.hideError()
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        self.view.endEditing(false)
    }
    
    func showHome() {
        // To keep the view hierarchy clean, the home vc can only be presented
        // from the landing vc. The login vc will validate the login, which sets
        // the keychain/caches appropriately, and then the landing vc will
        // actually start the session.
        //
        // The user will see the login page as a popover style on first launch.
        // This view should be seen rarely.
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Error Handling
    
    func show(error: String) {
        self.errorLabel.text = error
        self.errorLabel.isHidden = false
    }
    
    func hideError() {
        self.errorLabel.text = nil
        self.errorLabel.isHidden = true
    }
}
