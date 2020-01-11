//
//  API.swift
//  Shared
//
//  Created by Nathan Tornquist on 12/19/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Foundation

class API: APIQueueDelegate {
    
    // Shared Interface
    private static var _shared: API? = nil
    static var shared: API {
        if API._shared == nil {
            let storedURL = self.storedUrlOverride
            let safeUrl = API.generateSafe(url: storedURL)
            API._shared = API(baseURL: safeUrl)
        }
        return API._shared!
    }
    private var isShared: Bool { self === API.shared }
    
    // User Defaults
    private enum APIKeys: String {
        case storedSharedServerURLOverride = "time-api-configuration-shared-server-url-override"
    }
    private static var storedUrlOverride: String? {
        return UserDefaults.standard.string(forKey: API.APIKeys.storedSharedServerURLOverride.rawValue)
    }
    
    // Internal URL Interface
    private var _activeURLStorage: String
    private var activeURL: String {
        get {
            return self._activeURLStorage
        }
        set {
            if self.isShared {
                UserDefaults.standard.set(
                    newValue,
                    forKey: API.APIKeys.storedSharedServerURLOverride.rawValue
                )
            }
            
            self._activeURLStorage = API.generateSafe(url: newValue)
        }
    }
    
    // External URL Interface
    var baseURL: String { self.activeURL }
    func set(url newURL: String) -> Bool {
        let urlDifferent = self.isShared ? newURL != API.storedUrlOverride : newURL != self.activeURL
        guard urlDifferent else { return false }
        
        self.activeURL = newURL
        return true
    }
    
    // Authentication
    var isRefreshingToken = false
    var token: Token? = nil
    
    // API Retry and Default Configuration
    static private let defaultURL: String = "http://localhost:8000"
    var queue: APIQueue
    
    init(baseURL: String? = nil) {
        self._activeURLStorage = API.generateSafe(url: baseURL)
        
        self.queue = APIQueue(maximumFailures: 2)
        self.queue.delegate = self
    }
    
    enum HttpMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }

    enum HttpEncoding {
        case json
        case formUrlEncoded
    }
    
    // Internal codable object consumed by delete requests
    // Success is internal to this class and will not be stored in APIQueue
    struct Success: Codable {
        var success: Bool
    }

    func GET<T>(_ pathComponent: String, urlComponents: [String:String] = [:], auth: Bool = true, completion: @escaping (T?, Error?) -> (), sideEffects: ((T) -> ())? = nil) where T : Decodable {
        self.timeRequest(path: pathComponent, urlComponents: urlComponents, method: .GET, body: nil, encoding: nil, authorized: auth, completion: completion, sideEffects: sideEffects)
    }

    func POST<T>(_ pathComponent: String, _ body: [String: Any]? = nil, auth: Bool = true, encoding: HttpEncoding? = nil, completion: @escaping (T?, Error?) -> (), sideEffects: ((T) -> ())? = nil) where T : Decodable {
        let requestEncoding = body != nil && encoding == nil ? .json : encoding
        self.timeRequest(path: pathComponent, method: .POST, body: body, encoding: requestEncoding, authorized: auth, completion: completion, sideEffects: sideEffects)
    }
    
    func PUT<T>(_ pathComponent: String, _ body: [String: Any]? = nil, completion: @escaping (T?, Error?) -> (), sideEffects: ((T) -> ())? = nil) where T : Decodable {
        self.timeRequest(path: pathComponent, method: .PUT, body: body, encoding: .json, authorized: true, completion: completion, sideEffects: sideEffects)
    }
    
    func DELETE(_ pathComponent: String, _ body: [String: Any]? = nil, completion: @escaping (Error?) -> ()) {
        let internalCompletion = { (success: Success?, error: Error?) in
            guard error == nil else { completion(error); return }
            let result = success?.success ?? false
            let finalError = result ? nil : TimeError.requestFailed("Deletion did not return success")
            completion(finalError)
        }
        
        let encoding = body != nil ? HttpEncoding.json : nil
        
        self.timeRequest(path: pathComponent, method: .DELETE, body: body, encoding: encoding, authorized: true, completion: internalCompletion, sideEffects: nil)
    }

    func timeRequest<T>(path pathComponent: String, urlComponents: [String:String] = [:], method: HttpMethod, body: [String: Any]?, encoding: HttpEncoding?, authorized: Bool, completion: @escaping (T?, Error?) -> (), sideEffects: ((T) -> ())? = nil) where T : Decodable {
        // Build URL
        guard var url = URL(string: self.baseURL) else {
            complexCompletion(nil, TimeError.unableToSendRequest("Cannot build URL"), completion, sideEffects)
            return
        }
        
        url.appendPathComponent(pathComponent)
        
        if urlComponents.count > 0 {
            var components = URLComponents(string: url.absoluteString)
            components?.queryItems = urlComponents.map { (item) -> URLQueryItem in URLQueryItem(name: item.key, value: item.value) }
            guard let componentsURL = components?.url else {
                complexCompletion(nil, TimeError.unableToSendRequest("Cannot build URL with components"), completion, sideEffects)
                return
            }
            url = componentsURL
        }
        
        // Build Body and Headers
        guard encoding == nil && body == nil || encoding != nil && body != nil else {
            complexCompletion(nil, TimeError.unableToSendRequest("Mismatched body and encoding"), completion, sideEffects)
            return
        }
        
        var httpBody: Data?
        var headers: [String: String] = [:]
        if body != nil && encoding != nil {
            do {
                (httpBody, headers) = try self.buildBody(method: method, body: body!, encoding: encoding!)
            } catch let error as TimeError {
                complexCompletion(nil, error, completion, sideEffects)
                return
            } catch {
                let returnError = TimeError.requestFailed(error.localizedDescription)
                complexCompletion(nil, returnError, completion, sideEffects)
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
            completion: completion,
            sideEffects: sideEffects
        )
        
        self.sendRequest(apiRequest)
    }
    
    func sendRequest<T>(_ apiRequest: APIRequest<T>) where T : Decodable {
        var request: URLRequest!
        do {
            request = try apiRequest.buildRequest(for: self)
        } catch let error as TimeError {
            completeRequest(apiRequest, nil, error)
            return
        } catch {
            let returnError = TimeError.requestFailed(error.localizedDescription)
            completeRequest(apiRequest, nil, returnError)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let errorCode = (error as NSError?)?.code ?? -1
                var returnError: TimeError? = nil
                switch errorCode {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorCannotConnectToHost,
                     NSURLErrorCannotFindHost:
                    returnError = TimeError.unableToReachServer
                default:
                    let message = error as? String ?? ""
                    returnError = TimeError.requestFailed(message)
                }
                
                self.completeRequest(apiRequest, nil, returnError)
                self.queue.remove(request: apiRequest)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                if (httpStatus.statusCode == 401) {
                    if let responseObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject],
                        let message = responseObject["message"] as? String {
                     
                        let isFailedRefresh = message == "Refresh expired"
                        let isFailedAccess = message == "Token expired"
                        
                        if isFailedRefresh {
                            // Return failure on self
                        } else if isFailedAccess {
                            let marked = self.queue.markRequestAsFailed(apiRequest)
                            self.handleFailedAccess()
                            // If tracked, return immediately. Else dequeue and complete request
                            if (marked) { return }
                        } else {
                            // Non-token related error. Use generic error callback
                        }
                    }
                }

                self.completeRequest(apiRequest, nil, TimeError.httpFailure(httpStatus.statusCode.description))
                self.queue.remove(request: apiRequest)
                return
            }
            
            self.completeRequest(apiRequest, data, nil)
            self.queue.remove(request: apiRequest)
        }
        
        apiRequest.task = task
        self.queue.store(request: apiRequest)
        
        task.resume()
    }
    
    // MARK: - Token Refresh

    func handleFailedAccess() {
        guard self.isRefreshingToken == false else { return }
        
        self.isRefreshingToken = true
        
        self.refreshToken { (newToken, error) in
            self.isRefreshingToken = false
            
            guard error == nil else {
                let error = TimeError.authenticationFailure("Unable to acquire active access token")
                NotificationCenter.default.post(name: .TimeAPIAutoRefreshFailed, object: self)
                self.queue.failAllFailedRequests(with: error)
                return
            }
            
            NotificationCenter.default.post(name: .TimeAPIAutoRefreshedToken, object: self)
            self.queue.retryAllFailedRequests()
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildBody(method: HttpMethod, body: [String: Any], encoding: HttpEncoding) throws -> (Data?, [String: String]) {
        var data: Data?
        var headers: [String: String] = [:]
        
        switch (method, encoding) {
        case (HttpMethod.POST, HttpEncoding.json),
             (HttpMethod.PUT, HttpEncoding.json),
             (HttpMethod.DELETE, HttpEncoding.json):
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
                guard let value = body[key], let stringValue = value as? String else {
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
    
    func completeRequest<T>(_ apiRequest: APIRequest<T>, _ data: Data?, _ error: Error?) where T : Decodable {
        complexCompletion(data, error, apiRequest.completion, apiRequest.sideEffects)
    }
    
    func complexCompletion<T>(_ data: Data?, _ error: Error?, _ completion: (T?, Error?) -> (), _ sideEffects: ((T) -> ())? = nil) where T : Decodable {
        guard let data = data, error == nil else {
            let returnError = error ?? TimeError.requestFailed("Missing response data")
            completion(nil, returnError)
            return
        }
        
        do {
            let t = try JSONDecoder().decode(T.self, from: data)
            sideEffects?(t)
            completion(t, nil)
        } catch {
            completion(nil, TimeError.unableToDecodeResponse)
        }
    }
    
    // MARK: - URL Helper
    
    private static func generateSafe(url: String?) -> String {
        guard url != nil && url!.trimmingCharacters(in: .whitespaces).count > 0 else {
            return API.defaultURL
        }
        return url!
    }
}
