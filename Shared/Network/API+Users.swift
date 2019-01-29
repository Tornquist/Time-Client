//
//  API+Users.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension API {
    func createUser(withEmail email: String, andPassword password: String, completionHandler: @escaping (User?, Error?) -> ()) {
        POST("/users", ["email": email, "password": password], auth: false) { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completionHandler(user, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
}
