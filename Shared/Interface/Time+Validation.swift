//
//  TimeValidation.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension Time {
    public static func validate(email emailCandidate: String?, validateContents: Bool = true) -> (String?, [ValidationError]) {
        guard let email = emailCandidate else { return (nil, [.emailRequired]) }
        guard email.count > 0 else { return (nil, [.emailRequired]) }
        guard validateContents else { return (email, []) }
        
        let emailRange = NSRange(location: 0, length: email.utf16.count)
        let emailRegex = try! NSRegularExpression(pattern: "^(([^<>()\\[\\]\\\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\\\.,;:\\s@\"]+)*)|(\".+\"))@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}])|(([a-zA-Z\\-0-9]+\\.)+[a-zA-Z]{2,}))$")
        let validEmail = emailRegex.firstMatch(in: email, options: [], range: emailRange) != nil
        
        guard validEmail else { return (nil, [.emailInvalid]) }
        
        return (email, [])
    }
    
    public static func validate(password passwordCandidate: String?, validateContents: Bool = true) -> (String?, [ValidationError]) {
        guard let password = passwordCandidate else { return (nil, [.passwordRequired]) }
        guard password.count > 0 else { return (nil, [.passwordRequired]) }
        guard validateContents else { return (password, []) }
        
        guard password.count >= 8 else { return (nil, [.passwordTooShort]) }
        guard password.count <= 30 else { return (nil, [.passwordTooLong]) }
        
        let passwordRange = NSRange(location: 0, length: password.utf16.count)
        let passwordRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9@*#!%$_-]{8,30})$")
        let validPassword = passwordRegex.firstMatch(in: password, options: [], range: passwordRange) != nil
        
        guard validPassword else {
            let filteredPassword = password.replacingOccurrences(of: "[a-z0-9@*#!%$_-]", with: "", options: [.regularExpression, .caseInsensitive])
            let badCharacters = Array(Set(filteredPassword)).map({ $0.description }).sorted().joined()
            return (nil, [.passwordInvalidCharacters(badCharacters)])
        }
        
        return (password, [])
    }
}

public enum ValidationError {
    case emailRequired
    case emailInvalid
    
    case passwordRequired
    case passwordTooShort
    case passwordTooLong
    case passwordInvalidCharacters(String)
    
    public var description: String {
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

extension ValidationError: Equatable {
    public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.emailRequired, .emailRequired):
            return true
        case (.emailInvalid, .emailInvalid):
            return true
        case (.passwordRequired, .passwordRequired):
            return true
        case (.passwordTooShort, .passwordTooShort):
            return true
        case (.passwordTooLong, .passwordTooLong):
            return true
        case (.passwordInvalidCharacters(let l), .passwordInvalidCharacters(let r)):
            return l == r
        case (.emailRequired, _), (.emailInvalid, _), (.passwordRequired, _), (.passwordTooShort, _), (.passwordTooLong, _), (.passwordInvalidCharacters, _):
            return false
        }
    }
}
