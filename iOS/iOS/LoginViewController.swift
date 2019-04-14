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
        
        let signUp = sender == self.signUpButton
        let (email, emailErrors) = Time.validate(email: self.emailTextField.text, validateContents: signUp)
        let (password, passwordErrors) = Time.validate(password: self.passwordTextField.text, validateContents: signUp)
        
        guard emailErrors.count == 0 && passwordErrors.count == 0 else {
            let displayError = (emailErrors + passwordErrors).map({ $0.description }).joined(separator: "\n")
            self.show(error: displayError)
            return
        }
        guard let safeEmail = email, let safePassword = password else {
            self.show(error: NSLocalizedString("An unknown error has occurred.", comment: ""))
            return
        }
        
        let complete = { (allowDuplicate: Bool) in
            return { (error: Error?) in
                guard error == nil else {
                    let timeError = error as? TimeError
                    let is409 = timeError == TimeError.httpFailure("409")
                    let duplicateError = allowDuplicate && is409
                    let message = duplicateError
                        ? NSLocalizedString("Email already associated with an account.", comment: "")
                        : NSLocalizedString("An unknown error has occurred.", comment: "")
                    
                    DispatchQueue.main.async { self.show(error: message) }
                    return
                }
                
                DispatchQueue.main.async { self.showHome() }
            }
        }
        
        if signUp {
            Time.shared.register(email: safeEmail, password: safePassword, completionHandler: complete(true))
        } else {
            Time.shared.authenticate(email: safeEmail, password: safePassword, completionHandler: complete(false))
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
