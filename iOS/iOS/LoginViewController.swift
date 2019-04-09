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
    
    enum ValidationError {
        case emailRequired
        case emailInvalid
        
        case passwordRequired
        case passwordTooShort
        case passwordTooLong
        case passwordInvalidCharacters
        
        var description: String {
            switch self {
            case .emailRequired:
                return NSLocalizedString("Email required.", comment: "")
            case .emailInvalid:
                return NSLocalizedString("Email not recognized.", comment: "")
            case .passwordRequired:
                return NSLocalizedString("Password required.", comment: "")
            case .passwordTooShort:
                return NSLocalizedString("Password length invalid. Must be at least 8 characters.", comment: "")
            case .passwordTooLong:
                return NSLocalizedString("Password length invalid. Must be 30 characters or less.", comment: "")
            case .passwordInvalidCharacters:
                return NSLocalizedString("Password can contain a-z, A-Z, 0-9 or @*#!%$_-", comment: "")
            }
        }
    }
    
    func validate(email emailCandidate: String?, validateContents: Bool) -> (String?, [ValidationError]) {
        guard let email = emailCandidate else { return (nil, [.emailRequired]) }
        guard email.count > 0 else { return (nil, [.emailRequired]) }
        guard validateContents else { return (email, []) }
        
        let emailRange = NSRange(location: 0, length: email.utf16.count)
        let emailRegex = try! NSRegularExpression(pattern: "^(([^<>()\\[\\]\\\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\\\.,;:\\s@\"]+)*)|(\".+\"))@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}])|(([a-zA-Z\\-0-9]+\\.)+[a-zA-Z]{2,}))$")
        let validEmail = emailRegex.firstMatch(in: email, options: [], range: emailRange) != nil
        
        guard validEmail else { return (nil, [.emailInvalid]) }
        
        return (email, [])
    }
    
    func validate(password passwordCandidate: String?, validateContents: Bool = true) -> (String?, [ValidationError]) {
        guard let password = passwordCandidate else { return (nil, [.passwordRequired]) }
        guard password.count > 0 else { return (nil, [.passwordRequired]) }
        guard validateContents else { return (password, []) }
        
        guard password.count >= 8 else { return (nil, [.passwordTooShort]) }
        guard password.count <= 30 else { return (nil, [.passwordTooLong]) }
        
        let passwordRange = NSRange(location: 0, length: password.utf16.count)
        let passwordRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9@*#!%$_-]{8,30})$")
        let validPassword = passwordRegex.firstMatch(in: password, options: [], range: passwordRange) != nil
        
        guard validPassword else { return (nil, [.passwordInvalidCharacters]) }
        
        return (password, [])
    }
    
    @IBAction func handleButtonPress(_ sender: UIButton) {
        self.hideError()
        
        let signUp = sender == self.signUpButton
        let (email, emailErrors) = validate(email: self.emailTextField.text, validateContents: signUp)
        let (password, passwordErrors) = validate(password: self.passwordTextField.text, validateContents: signUp)
        
        guard emailErrors.count == 0 && passwordErrors.count == 0 else {
            let displayError = (emailErrors + passwordErrors).map({ $0.description }).joined(separator: "\n")
            self.show(error: displayError)
            return
        }
        guard let safeEmail = email, let safePassword = password else {
            self.show(error: NSLocalizedString("An unknown error has occurred.", comment: ""))
            return
        }
        
        if signUp {
            // Not supported
        } else {
            Time.shared.authenticate(username: safeEmail, password: safePassword) { error in
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
