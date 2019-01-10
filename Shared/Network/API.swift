//
//  API.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

public enum TimeError: Error {
    case unableToSendRequest(String)
    case unableToDecodeResponse()
    case requestFailed(String)
    case httpFailure(String)
}

class API {
    static let shared = API()
    
    let baseURL = "http://localhost:8000"
    
    func getToken(withUsername username: String, andPassword password: String, completionHandler: @escaping (Token?, Error?) -> ()) {
        guard var path = URL(string: baseURL) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot build URL"))
            return
        }
        
        path.appendPathComponent("/oauth/token")
        var request = URLRequest(url: path)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let rfc3986Reserved = CharacterSet(charactersIn: " %!*'();:@+$,/?#[]&=")
        guard
            let encodedUsername: String = username.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted),
            let encodedPassword: String = password.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted)
            else {
                completionHandler(nil, TimeError.unableToSendRequest("Cannot encode credentials"))
                return
        }
        
        let bodyString = "grant_type=password&username=\(encodedUsername)&password=\(encodedPassword)"
        guard let bodyData = bodyString.data(using: String.Encoding.utf8) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot encode credentials"))
            return
        }

        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let message = error as? String ?? ""
                completionHandler(nil, TimeError.requestFailed(message))
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completionHandler(nil, TimeError.httpFailure(httpStatus.statusCode.description))
                return
            }
            
            do {
                let token = try JSONDecoder().decode(Token.self, from: data)
                completionHandler(token, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
        
        task.resume()
    }
    
    func refreshToken(with token: Token, completionHandler: @escaping (Token?, Error?) -> ()) {
        guard var path = URL(string: baseURL) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot build URL"))
            return
        }
        
        path.appendPathComponent("/oauth/token")
        var request = URLRequest(url: path)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let rfc3986Reserved = CharacterSet(charactersIn: " %!*'();:@+$,/?#[]&=")
        guard
            let encodedToken: String = token.refresh.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted)
            else {
                completionHandler(nil, TimeError.unableToSendRequest("Cannot encode credentials"))
                return
        }
        
        let bodyString = "grant_type=refresh_token&refresh_token=\(encodedToken)"
        guard let bodyData = bodyString.data(using: String.Encoding.utf8) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot encode credentials"))
            return
        }
        
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let message = error as? String ?? ""
                completionHandler(nil, TimeError.requestFailed(message))
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completionHandler(nil, TimeError.httpFailure(httpStatus.statusCode.description))
                return
            }
            
            do {
                let token = try JSONDecoder().decode(Token.self, from: data)
                completionHandler(token, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
        
        task.resume()
    }
    
    func createUser(withEmail email: String, andPassword password: String, completionHandler: @escaping (User?, Error?) -> ()) {
        guard var path = URL(string: baseURL) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot build URL"))
            return
        }
        
        path.appendPathComponent("/users")
        var request = URLRequest(url: path)
        request.httpMethod = "POST"
        
        let rawBody: [String: String] = [
            "email": email,
            "password": password
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: rawBody, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot encode body"))
            return
        }
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let message = error as? String ?? ""
                completionHandler(nil, TimeError.requestFailed(message))
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completionHandler(nil, TimeError.httpFailure(httpStatus.statusCode.description))
                return
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completionHandler(user, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
        
        task.resume()
    }
}
