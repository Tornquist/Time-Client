//
//  Test_TimeValidation.swift
//  Shared
//
//  Created by Nathan Tornquist on 4/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

import XCTest
@testable import TimeSDK

class Test_TimeValidation: XCTestCase {
    func test_nilEmail() {
        let (email, errors) = Time.validate(email: nil)
        XCTAssertNil(email)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.emailRequired))
    }
    
    func test_emptyEmail() {
        let (email, errors) = Time.validate(email: "")
        XCTAssertNil(email)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.emailRequired))
    }
    
    func test_badEmailWithoutContentValidation() {
        let (email, errors) = Time.validate(email: "notAnEmail", validateContents: false)
        XCTAssertEqual(email, "notAnEmail")
        XCTAssertEqual(errors.count, 0)
    }
    
    func test_badEmailWithContentValidation() {
        var email: String? = nil
        var errors: [ValidationError] = []
        
        (email, errors) = Time.validate(email: "notAnEmail", validateContents: true)
        XCTAssertNil(email)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.emailInvalid))
        
        // Default is validateContents = true
        (email, errors) = Time.validate(email: "notAnEmail")
        XCTAssertNil(email)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.emailInvalid))
    }
    
    func test_acceptsCommonEmails() {
        var email: String? = nil
        var errors: [ValidationError] = []
        
        (email, errors) = Time.validate(email: "name@domain.com", validateContents: true)
        XCTAssertEqual(email, "name@domain.com")
        XCTAssertEqual(errors.count, 0)
        
        (email, errors) = Time.validate(email: "name@domain.org", validateContents: true)
        XCTAssertEqual(email, "name@domain.org")
        XCTAssertEqual(errors.count, 0)
        
        (email, errors) = Time.validate(email: "name@domain.net", validateContents: true)
        XCTAssertEqual(email, "name@domain.net")
        XCTAssertEqual(errors.count, 0)
        
        (email, errors) = Time.validate(email: "name@domain.io", validateContents: true)
        XCTAssertEqual(email, "name@domain.io")
        XCTAssertEqual(errors.count, 0)
        
        (email, errors) = Time.validate(email: "name@domain.me", validateContents: true)
        XCTAssertEqual(email, "name@domain.me")
        XCTAssertEqual(errors.count, 0)
        
        (email, errors) = Time.validate(email: "name.with.periods@domain.me", validateContents: true)
        XCTAssertEqual(email, "name.with.periods@domain.me")
        XCTAssertEqual(errors.count, 0)

        (email, errors) = Time.validate(email: "name+tag@domain.me", validateContents: true)
        XCTAssertEqual(email, "name+tag@domain.me")
        XCTAssertEqual(errors.count, 0)
        
        (email, errors) = Time.validate(email: "name.with.periods+tag@domain.me", validateContents: true)
        XCTAssertEqual(email, "name.with.periods+tag@domain.me")
        XCTAssertEqual(errors.count, 0)
    }
    
    func test_nilPassword() {
        let (password, errors) = Time.validate(password: nil)
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordRequired))
    }
    
    func test_emptyPassword() {
        let (password, errors) = Time.validate(password: "")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordRequired))
    }
    
    func test_badPasswordWithoutContentValidation() {
        // Too short -> would fail with validation on.
        let (password, errors) = Time.validate(password: "1", validateContents: false)
        XCTAssertEqual(password, "1")
        XCTAssertEqual(errors.count, 0)
    }
    
    func test_shortPassword() {
        let (password, errors) = Time.validate(password: "1234")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordTooShort))
    }
    
    func test_longPassword() {
        let (password, errors) = Time.validate(password: "123456789012345678901234567890-")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordTooLong))
    }
    
    func test_badPasswordCharacters() {
        var password: String? = nil
        var errors: [ValidationError] = []
        
        (password, errors) = Time.validate(password: "12345678(")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordInvalidCharacters("(")))
        
        (password, errors) = Time.validate(password: "12345678👍")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordInvalidCharacters("👍")))
        
        (password, errors) = Time.validate(password: "12345678^")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.contains(.passwordInvalidCharacters("^")))
        
        (password, errors) = Time.validate(password: "12345678;(^)))(")
        XCTAssertNil(password)
        XCTAssertEqual(errors.count, 1)
        print(errors)
        XCTAssertTrue(errors.contains(.passwordInvalidCharacters("();^")))
    }
    
    func test_goodPasswords() {
        var password: String? = nil
        var errors: [ValidationError] = []
        
        (password, errors) = Time.validate(password: "password")
        XCTAssertEqual(password, "password")
        XCTAssertEqual(errors.count, 0)
        
        (password, errors) = Time.validate(password: "myPassword")
        XCTAssertEqual(password, "myPassword")
        XCTAssertEqual(errors.count, 0)
        
        (password, errors) = Time.validate(password: "myPassword$!")
        XCTAssertEqual(password, "myPassword$!")
        XCTAssertEqual(errors.count, 0)
        
        (password, errors) = Time.validate(password: "a__-_myPa55w0rd$!")
        XCTAssertEqual(password, "a__-_myPa55w0rd$!")
        XCTAssertEqual(errors.count, 0)
    }
    
    func test_validationError() {
        XCTAssertEqual(
            ValidationError.emailRequired.description,
            "Email required."
        )
        XCTAssertEqual(
            ValidationError.emailInvalid.description,
            "Email not recognized."
        )
        XCTAssertEqual(
            ValidationError.passwordRequired.description,
            "Password required."
        )
        XCTAssertEqual(
            ValidationError.passwordTooShort.description,
            "Password length invalid. Must be at least 8 characters."
        )
        XCTAssertEqual(
            ValidationError.passwordTooLong.description,
            "Password length invalid. Must be 30 characters or less."
        )
        XCTAssertEqual(
            ValidationError.passwordInvalidCharacters("&").description,
            [
                "Password can contain a-z, A-Z, 0-9 or @*#!%$_-",
                "Invalid character: &"
            ].joined(separator: "\n")
        )
        XCTAssertEqual(
            ValidationError.passwordInvalidCharacters("&()").description,
            [
                "Password can contain a-z, A-Z, 0-9 or @*#!%$_-",
                "Invalid characters: &()"
            ].joined(separator: "\n")
        )
        
        XCTAssertEqual(ValidationError.emailRequired, ValidationError.emailRequired)
        XCTAssertEqual(ValidationError.emailInvalid, ValidationError.emailInvalid)
        XCTAssertEqual(ValidationError.passwordRequired, ValidationError.passwordRequired)
        XCTAssertEqual(ValidationError.passwordTooShort, ValidationError.passwordTooShort)
        XCTAssertEqual(ValidationError.passwordTooLong, ValidationError.passwordTooLong)
        XCTAssertEqual(ValidationError.passwordInvalidCharacters("a"), ValidationError.passwordInvalidCharacters("a"))
        
        // Intentionally allow invalidCharacters errors with different details to match
        XCTAssertEqual(ValidationError.passwordInvalidCharacters("a"), ValidationError.passwordInvalidCharacters("b"))
        
        XCTAssertNotEqual(ValidationError.emailRequired, ValidationError.emailInvalid)
        XCTAssertNotEqual(ValidationError.emailInvalid, ValidationError.passwordRequired)
        XCTAssertNotEqual(ValidationError.passwordRequired, ValidationError.passwordTooShort)
        XCTAssertNotEqual(ValidationError.passwordTooShort, ValidationError.passwordTooLong)
        XCTAssertNotEqual(ValidationError.passwordTooLong, ValidationError.passwordInvalidCharacters("a"))
        XCTAssertNotEqual(ValidationError.passwordInvalidCharacters("a"), ValidationError.emailRequired)
    }
    
    func test_validationErrorExtractingBadCharacters() {
        let returnedError = ValidationError.passwordInvalidCharacters("&")
        let details = returnedError.details
        XCTAssertEqual(details, "&")
    }
}
