//
//  API+Tokens.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension API {
    func getToken(withUsername username: String, andPassword password: String, completionHandler: @escaping (Token?, Error?) -> ()) {
        let body = [
            "grant_type" : "password",
            "username": username,
            "password": password
        ]
        POST("/oauth/token", body, auth: false, encoding: .formUrlEncoded) { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let token = try JSONDecoder().decode(Token.self, from: data)
                self.token = token
                completionHandler(token, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
    
    func refreshToken(completionHandler: @escaping (Token?, Error?) -> ()) {
        guard let token = self.token else {
            completionHandler(nil, TimeError.unableToSendRequest("Missing token"))
            return
        }
        
        let body = [
            "grant_type" : "refresh_token",
            "refresh_token": token.refresh
        ]
        POST("/oauth/token", body, auth: false, encoding: .formUrlEncoded) { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let token = try JSONDecoder().decode(Token.self, from: data)
                self.token = token
                completionHandler(token, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
}
