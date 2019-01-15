//
//  API+Accounts.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

extension API {
    func createAccount(completionHandler: @escaping (Account?, Error?) -> ()) {
        POST("/accounts") { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let account = try JSONDecoder().decode(Account.self, from: data)
                completionHandler(account, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
    
    func getAccounts(completionHandler: @escaping ([Account]?, Error?) -> ()) {
        GET("/accounts") { (data, error) in
            guard let data = data, error == nil else {
                let returnError = error ?? TimeError.requestFailed("Missing response data")
                completionHandler(nil, returnError)
                return
            }
            
            do {
                let accounts = try JSONDecoder().decode([Account].self, from: data)
                completionHandler(accounts, nil)
            } catch {
                completionHandler(nil, TimeError.unableToDecodeResponse())
            }
        }
    }
}
