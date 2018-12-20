//
//  Time.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

public class Time {
    public static let shared = Time()
    
    public func authenticate(email: String, password: String) {
        API.shared.getToken(with: email, and: password) { (token, error) in
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            
            print(token?.userID.description)
        }
    }
}
