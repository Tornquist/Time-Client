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
        POST("/accounts", completion: completionHandler)
    }
    
    func getAccounts(completionHandler: @escaping ([Account]?, Error?) -> ()) {
        GET("/accounts", completion: completionHandler)
    }
}
