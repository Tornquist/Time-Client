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
    case authenticationFailure(String)
}

class API {
    static let shared = API()
    
    var baseURL: String = "http://localhost:8000"
    var token: Token? = nil
    
    enum HttpMethod: String {
        case GET = "GET"
        case POST = "POST"
    }

    enum HttpEncoding {
        case json
        case formUrlEncoded
    }

    func GET(_ pathComponent: String, auth: Bool = true, completionHandler: @escaping (Data?, TimeError?) -> ()) {
        self.timeRequest(path: pathComponent, method: .GET, body: nil, encoding: nil, authorized: auth, completionHandler: completionHandler)
    }

    func POST(_ pathComponent: String, _ body: [String: Any]? = nil, auth: Bool = true, encoding: HttpEncoding? = nil, completionHandler: @escaping (Data?, TimeError?) -> ()) {
        let requestEncoding = body != nil && encoding == nil ? .json : encoding
        self.timeRequest(path: pathComponent, method: .POST, body: body, encoding: requestEncoding, authorized: auth, completionHandler: completionHandler)
    }

    func timeRequest(path pathComponent: String, method: HttpMethod, body: [String: Any]?, encoding: HttpEncoding?, authorized: Bool, completionHandler: @escaping (Data?, TimeError?) -> ()) {
        guard var path = URL(string: self.baseURL) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot build URL"))
            return
        }
        
        path.appendPathComponent(pathComponent)
        var request = URLRequest(url: path)
        request.httpMethod = method.rawValue
        
        guard encoding == nil && body == nil || encoding != nil && body != nil else {
            completionHandler(nil, TimeError.unableToSendRequest("Mismatched body and encoding"))
            return
        }
        
        if encoding != nil {
            switch (method, encoding!) {
            case (HttpMethod.POST, HttpEncoding.json):
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                guard let httpBody = try? JSONSerialization.data(withJSONObject: body!, options: JSONSerialization.WritingOptions.prettyPrinted) else {
                    completionHandler(nil, TimeError.unableToSendRequest("Cannot encode body"))
                    return
                }
                request.httpBody = httpBody
                
            case (HttpMethod.POST, HttpEncoding.formUrlEncoded):
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let rfc3986Reserved = CharacterSet(charactersIn: " %!*'();:@+$,/?#[]&=")
                var safeData: [(String, String)] = []
                body!.keys.forEach { (key) in
                    guard let value = body![key] else {
                        completionHandler(nil, TimeError.unableToSendRequest("Cannot encode null for x-www-form-urlencoded"))
                        return
                    }
                    guard let stringValue = value as? String else {
                        completionHandler(nil, TimeError.unableToSendRequest("x-www-form-urlencoded requires string values"))
                        return
                    }
                    guard
                        let encodedKey: String = key.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted),
                        let encodedValue: String = stringValue.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted)
                        else {
                            completionHandler(nil, TimeError.unableToSendRequest("Cannot key or value for x-www-form-urlencoded"))
                            return
                    }
                    safeData.append((encodedKey, encodedValue))
                }
                let bodyString = safeData.map({ "\($0.0)=\($0.1)"}).joined(separator: "&")
                guard let bodyData = bodyString.data(using: String.Encoding.utf8) else {
                    completionHandler(nil, TimeError.unableToSendRequest("Cannot encode rfc3986 safe data"))
                    return
                }
                request.httpBody = bodyData
                
            default:
                completionHandler(nil, TimeError.unableToSendRequest("Encoding not supported for method type"))
                return
            }
        }
        
        if authorized {
            guard let tokenValue = self.token?.token else {
                completionHandler(nil, TimeError.authenticationFailure("Missing authentication token"))
                return
            }
            request.setValue("Bearer \(tokenValue)", forHTTPHeaderField: "Authorization")
        }
        
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
            
            completionHandler(data, nil)
        }
        
        task.resume()
    }
}
