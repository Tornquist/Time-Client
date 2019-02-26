//
//  APIQueue.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/11/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

protocol APIQueueDelegate: class {
    func sendRequest<T>(_ apiRequest: APIRequest<T>) where T : Decodable
    func completeRequest<T>(_ apiRequest: APIRequest<T>, _ data: Data?, _ error: Error?) where T : Decodable
}

class APIQueue {
    
    var maximumFailures: Int
    weak var delegate: APIQueueDelegate?
    
    init(maximumFailures: Int = 2) {
        self.maximumFailures = maximumFailures
    }
    
    // MARK: - Request Stores
    
    var activeTokenRequests: [String: APIRequest<Token>] = [:]
    var activeUserRequests: [String: APIRequest<User>] = [:]
    var activeAccountRequests: [String: APIRequest<Account>] = [:]
    var activeAccountsRequests: [String: APIRequest<[Account]>] = [:]
    var activeCategoryRequests: [String: APIRequest<Category>] = [:]
    var activeCategoriesRequests: [String: APIRequest<[Category]>] = [:]
    var activeEntryRequests: [String: APIRequest<Entry>] = [:]
    var activeEntriesRequests: [String: APIRequest<[Entry]>] = [:]
    
    // MARK: - Interface
    
    func store<T>(request: APIRequest<T>) {
        _ = self.set(request: request)
    }
    
    func remove<T>(request: APIRequest<T>) {
        request.removeReferences()
        self.del(request: request)
    }
    
    func markRequestAsFailed<T>(_ request: APIRequest<T>) -> Bool {
        // Only handle requests being tracked
        guard self.exists(request.id) else { return false }
        
        request.reportFailure()
        
        guard request.failureCount >= self.maximumFailures else { return true }

        let finalError = TimeError.authenticationFailure("Maximum number of access failures")
        self.fail(request: request, with: finalError)
        
        return true
    }
    
    func retryAllFailedRequests() {
        self.retryAllFailedRequestsInStore(self.activeTokenRequests)
        self.retryAllFailedRequestsInStore(self.activeUserRequests)
        self.retryAllFailedRequestsInStore(self.activeAccountRequests)
        self.retryAllFailedRequestsInStore(self.activeAccountsRequests)
        self.retryAllFailedRequestsInStore(self.activeCategoryRequests)
        self.retryAllFailedRequestsInStore(self.activeCategoriesRequests)
        self.retryAllFailedRequestsInStore(self.activeEntryRequests)
        self.retryAllFailedRequestsInStore(self.activeEntriesRequests)
    }
    
    func failAllFailedRequests(with error: Error) {
        self.failAllFailedRequestsInStore(self.activeTokenRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeUserRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeAccountRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeAccountsRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeCategoryRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeCategoriesRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeEntryRequests, with: error)
        self.failAllFailedRequestsInStore(self.activeEntriesRequests, with: error)
    }
    
    // MARK: - Internal Interface
    
    private func exists(_ id: String) -> Bool {
        let isToken = self.activeTokenRequests[id] != nil
        let isUser = self.activeUserRequests[id] != nil
        let isAccount = self.activeAccountRequests[id] != nil
        let isAccounts = self.activeAccountsRequests[id] != nil
        let isCategory = self.activeCategoryRequests[id] != nil
        let isCategories = self.activeCategoriesRequests[id] != nil
        let isEntry = self.activeEntryRequests[id] != nil
        let isEntries = self.activeEntriesRequests[id] != nil
        
        return isToken || isUser || isAccount || isAccounts || isCategory || isCategories || isEntry || isEntries
    }
    
    private func set<T>(request: APIRequest<T>) -> Bool {
        switch request {
        case is APIRequest<Token>:
            self.activeTokenRequests[request.id] = (request as! APIRequest<Token>)
        case is APIRequest<User>:
            self.activeUserRequests[request.id] = (request as! APIRequest<User>)
        case is APIRequest<Account>:
            self.activeAccountRequests[request.id] = (request as! APIRequest<Account>)
        case is APIRequest<[Account]>:
            self.activeAccountsRequests[request.id] = (request as! APIRequest<[Account]>)
        case is APIRequest<Category>:
            self.activeCategoryRequests[request.id] = (request as! APIRequest<Category>)
        case is APIRequest<[Category]>:
            self.activeCategoriesRequests[request.id] = (request as! APIRequest<[Category]>)
        case is APIRequest<Entry>:
            self.activeEntryRequests[request.id] = (request as! APIRequest<Entry>)
        case is APIRequest<[Entry]>:
            self.activeEntriesRequests[request.id] = (request as! APIRequest<[Entry]>)
        default:
            // Cannot store. No retry supported
            return false
        }
        
        return true
    }
    
    private func del<T>(request: APIRequest<T>) {
        let id = request.id
        self.activeTokenRequests.removeValue(forKey: id)
        self.activeUserRequests.removeValue(forKey: id)
        self.activeAccountRequests.removeValue(forKey: id)
        self.activeAccountsRequests.removeValue(forKey: id)
        self.activeCategoryRequests.removeValue(forKey: id)
        self.activeCategoriesRequests.removeValue(forKey: id)
        self.activeEntryRequests.removeValue(forKey: id)
        self.activeEntriesRequests.removeValue(forKey: id)
    }
    
    private func fail<T>(request: APIRequest<T>, with error: Error) {
        switch request {
        case is APIRequest<Token>:
            if let item = self.activeTokenRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<User>:
            if let item = self.activeUserRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<Account>:
            if let item = self.activeAccountRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<[Account]>:
            if let item = self.activeAccountsRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<Category>:
            if let item = self.activeCategoryRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<[Category]>:
            if let item = self.activeCategoriesRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<Entry>:
            if let item = self.activeEntryRequests[request.id] { handleFail(request: item, with: error) }
        case is APIRequest<[Entry]>:
            if let item = self.activeEntriesRequests[request.id] { handleFail(request: item, with: error) }
        default:
            // Unreachable due to exists check
            break
        }
    }
    
    private func handleFail<T>(request: APIRequest<T>, with error: Error) where T : Decodable {
        self.delegate?.completeRequest(request, nil, error)
        self.remove(request: request)
    }
    
    private func retryAllFailedRequestsInStore<T>(_ store: [String: APIRequest<T>]) where T : Decodable {
        let requests = store.values.filter({ $0.failed })
        requests.forEach { (request) in
            request.failed = false
            self.delegate?.sendRequest(request)
        }
    }
    
    private func failAllFailedRequestsInStore<T>(_ store: [String: APIRequest<T>], with error: Error) where T : Decodable {
        let requests = store.values.filter({ $0.failed })
        requests.forEach { (request) in
            self.delegate?.completeRequest(request, nil, error)
            self.remove(request: request)
        }
    }
}
