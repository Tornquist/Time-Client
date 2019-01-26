//
//  API.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

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
        guard var url = URL(string: self.baseURL) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot build URL"))
            return
        }
        
        url.appendPathComponent(pathComponent)
        
        guard encoding == nil && body == nil || encoding != nil && body != nil else {
            completionHandler(nil, TimeError.unableToSendRequest("Mismatched body and encoding"))
            return
        }
        
        var httpBody: Data?
        var headers: [String: String] = [:]
        if body != nil && encoding != nil {
            do {
                (httpBody, headers) = try self.buildBody(method: method, body: body!, encoding: encoding!)
            } catch let error as TimeError {
                completionHandler(nil, error)
                return
            } catch {
                let returnError = TimeError.requestFailed(error.localizedDescription)
                completionHandler(nil, returnError)
                return
            }
        }
        
        let apiRequest = APIRequest.init(
            url: url,
            method: method.rawValue,
            authorized: authorized,
            headers: headers,
            body: httpBody,
            completion: completionHandler
        )
        
        var request: URLRequest!
        do {
            request = try apiRequest.buildRequest(for: self)
        } catch let error as TimeError {
            completionHandler(nil, error)
            return
        } catch {
            let returnError = TimeError.requestFailed(error.localizedDescription)
            completionHandler(nil, returnError)
            return
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
        
        apiRequest.task = task
        
        task.resume()
    }
    
    // MARK: - Internal Methods
    
    private func buildBody(method: HttpMethod, body: [String: Any], encoding: HttpEncoding) throws -> (Data?, [String: String]) {
        var data: Data?
        var headers: [String: String] = [:]
        
        switch (method, encoding) {
        case (HttpMethod.POST, HttpEncoding.json):
            headers["Content-Type"] = "application/json"
            guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.prettyPrinted) else {
                throw TimeError.unableToSendRequest("Cannot encode body")
            }
            data = httpBody
            
        case (HttpMethod.POST, HttpEncoding.formUrlEncoded):
            headers["Content-Type"] = "application/x-www-form-urlencoded"
            let rfc3986Reserved = CharacterSet(charactersIn: " %!*'();:@+$,/?#[]&=")
            var safeData: [(String, String)] = []
            try body.keys.forEach { (key) in
                guard let value = body[key] else {
                    throw TimeError.unableToSendRequest("Cannot encode null for x-www-form-urlencoded")
                }
                guard let stringValue = value as? String else {
                    throw TimeError.unableToSendRequest("x-www-form-urlencoded requires string values")
                }
                guard
                    let encodedKey: String = key.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted),
                    let encodedValue: String = stringValue.addingPercentEncoding(withAllowedCharacters: rfc3986Reserved.inverted)
                    else {
                        throw TimeError.unableToSendRequest("Cannot key or value for x-www-form-urlencoded")
                }
                safeData.append((encodedKey, encodedValue))
            }
            let bodyString = safeData.map({ "\($0.0)=\($0.1)"}).joined(separator: "&")
            guard let bodyData = bodyString.data(using: String.Encoding.utf8) else {
                throw TimeError.unableToSendRequest("Cannot encode rfc3986 safe data")
            }
            data = bodyData
            
        default:
            throw TimeError.unableToSendRequest("Encoding not supported for method type")
        }
        
        return (data, headers)
    }
}
