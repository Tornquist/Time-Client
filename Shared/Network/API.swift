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
    
    var isRefreshingToken = false
    var baseURL: String = "http://localhost:8000"
    var token: Token? = nil
    
    let maximumFailures = 2
    var activeRequests: [String: APIRequest] = [:]
    
    enum HttpMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
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
    
    func PUT(_ pathComponent: String, _ body: [String: Any]? = nil, completionHandler: @escaping (Data?, TimeError?) -> ()) {
        self.timeRequest(path: pathComponent, method: .PUT, body: body, encoding: .json, authorized: true, completionHandler: completionHandler)
    }

    func timeRequest(path pathComponent: String, method: HttpMethod, body: [String: Any]?, encoding: HttpEncoding?, authorized: Bool, completionHandler: @escaping (Data?, TimeError?) -> ()) {
        // Build URL
        guard var url = URL(string: self.baseURL) else {
            completionHandler(nil, TimeError.unableToSendRequest("Cannot build URL"))
            return
        }
        url.appendPathComponent(pathComponent)
        
        // Build Body and Headers
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
        
        // Build Request
        let apiRequest = APIRequest.init(
            url: url,
            method: method.rawValue,
            authorized: authorized,
            headers: headers,
            body: httpBody,
            completion: completionHandler
        )
        
        self.sendRequest(apiRequest, completionHandler: completionHandler)
    }
    
    func sendRequest(_ apiRequest: APIRequest, completionHandler: @escaping (Data?, TimeError?) -> ()) {
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
                self.remove(request: apiRequest)
                completionHandler(nil, TimeError.requestFailed(message))
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                if (httpStatus.statusCode == 401) {
                    if let responseObject = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject],
                        let message = responseObject["message"] as? String {
                     
                        let isFailedRefresh = message == "Refresh expired"
                        let isFailedAccess = message == "Token expired"
                        
                        if isFailedRefresh {
                            // Return failure on self
                        } else if isFailedAccess {
                            self.markRequestAsFailed(id: apiRequest.id)
                            self.refreshToken()
                            return
                        } else {
                            // Non-token related error. Use generic error callback
                        }
                    }
                }

                self.remove(request: apiRequest)
                completionHandler(nil, TimeError.httpFailure(httpStatus.statusCode.description))
                return
            }
            
            self.remove(request: apiRequest)
            
            completionHandler(data, nil)
        }
        
        apiRequest.task = task
        self.activeRequests[apiRequest.id] = apiRequest
        
        task.resume()
    }
    
    // MARK: - Token Refresh
    
    private func markRequestAsFailed(id: String) {
        guard let request = self.activeRequests[id] else { return }
        
        request.reportFailure()
        
        if (request.failureCount >= self.maximumFailures) {
            request.completion(nil, TimeError.authenticationFailure("Maximum number of access failures"))
            self.remove(request: request)
            return
        }
    }
    
    private func refreshToken() {
        guard self.isRefreshingToken == false else { return }
        
        self.isRefreshingToken = true
        
        self.refreshToken { (newToken, error) in
            guard error == nil else {
                self.failAllFailedRequests()
                return
            }
            
            self.isRefreshingToken = false
            self.retryAllFailedRequests()
        }
    }
    
    private func retryAllFailedRequests() {
        let requests = self.activeRequests.values.filter{( $0.failed )}
        requests.forEach { (request) in
            request.failed = false
            self.sendRequest(request, completionHandler: request.completion)
        }
    }
    
    private func failAllFailedRequests() {
        let requests = self.activeRequests.values.filter{( $0.failed )}
        requests.forEach { (request) in
            request.completion(nil, TimeError.authenticationFailure("Unable to acquire active access token"))
            self.remove(request: request)
        }
    }
    
    // MARK: - Helper Methods

    private func remove(request: APIRequest) {
        request.removeReferences()
        self.activeRequests.removeValue(forKey: request.id)
    }
    
    private func buildBody(method: HttpMethod, body: [String: Any], encoding: HttpEncoding) throws -> (Data?, [String: String]) {
        var data: Data?
        var headers: [String: String] = [:]
        
        switch (method, encoding) {
        case (HttpMethod.POST, HttpEncoding.json),
             (HttpMethod.PUT, HttpEncoding.json):
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
    
    // MARK: - Completion Options
    
    func handleDecodableCompletion<T>(_ data: Data?, _ error: Error?, completion: (T?, Error?) -> (), _ additionalActions: ((T) -> ())? = nil) where T : Decodable {
        guard let data = data, error == nil else {
            let returnError = error ?? TimeError.requestFailed("Missing response data")
            completion(nil, returnError)
            return
        }
        
        do {
            let t = try JSONDecoder().decode(T.self, from: data)
            additionalActions?(t)
            completion(t, nil)
        } catch {
            completion(nil, TimeError.unableToDecodeResponse())
        }
    }
}
