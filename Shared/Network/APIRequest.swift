//
//  APIRequest.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/26/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

class APIRequest {
    var url: URL
    var method: String
    var authorized: Bool
    var headers: [String: String]
    var body: Data?
    var completion: (Data?, TimeError?) -> ()
    var task: URLSessionDataTask? = nil
    
    init(url: URL, method: String, authorized: Bool, headers: [String: String], body: Data?, completion: @escaping (Data?, TimeError?) -> ()) {
        self.url = url
        self.method = method
        self.authorized = authorized
        self.headers = headers
        self.body = body
        self.completion = completion
    }
    
    func buildRequest(for api: API) throws -> URLRequest {
        var request = URLRequest(url: self.url)
        request.httpMethod = self.method
        request.httpBody = self.body
        
        if authorized {
            guard let tokenValue = api.token?.token else {
                throw TimeError.authenticationFailure("Missing authentication token")
            }
            request.setValue("Bearer \(tokenValue)", forHTTPHeaderField: "Authorization")
        }
        
        for (header, value) in self.headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        return request
    }
}
