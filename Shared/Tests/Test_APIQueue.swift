//
//  Test_APIQueue.swift
//  Shared
//
//  Created by Nathan Tornquist on 2/13/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import XCTest
@testable import TimeSDK

class Test_APIQueue: XCTestCase {
    
    var queue: APIQueue!
    
    override func setUp() {
        self.continueAfterFailure = false
        
        queue = APIQueue()
    }
    
    func verifyCounts(_ override: [String: Int] = [:]) {
        XCTAssertEqual(queue.activeTokenRequests.count, override["token"] ?? 0)
        XCTAssertEqual(queue.activeUserRequests.count, override["user"] ?? 0)
        XCTAssertEqual(queue.activeAccountRequests.count, override["account"] ?? 0)
        XCTAssertEqual(queue.activeAccountsRequests.count, override["accounts"] ?? 0)
        XCTAssertEqual(queue.activeCategoryRequests.count, override["category"] ?? 0)
        XCTAssertEqual(queue.activeCategoriesRequests.count, override["categories"] ?? 0)
    }
    
    func getUserRequest() -> APIRequest<User> {
        let url = URL(string: "https://test.com")!
        
        let request = APIRequest(
            url: url,
            method: "GET",
            authorized: true,
            headers: [:],
            body: nil,
            completion: { (user: User?, error: Error?) in
                print("completion")
        },
            sideEffects: nil
        )
        
        return request
    }
    
    class NotTrackedClass {}
    func getNotTrackedClassRequest() -> APIRequest<NotTrackedClass> {
        let url = URL(string: "https://test.com")!
        
        let request = APIRequest(
            url: url,
            method: "GET",
            authorized: true,
            headers: [:],
            body: nil,
            completion: { (user: NotTrackedClass?, error: Error?) in
                print("completion")
        },
            sideEffects: nil
        )
        
        return request
    }
    
    class MockDelegate: APIQueueDelegate {
        var send: (() -> ())? = nil
        var complete: ((_ data: Data?, _ error: Error?) -> ())? = nil
        
        func sendRequest<T>(_ apiRequest: APIRequest<T>) where T : Decodable {
            self.send?()
        }
        
        func completeRequest<T>(_ apiRequest: APIRequest<T>, _ data: Data?, _ error: Error?) where T : Decodable {
            self.complete?(data, error)
        }
    }
    
    func test_storingKnownModels() {
        let request = getUserRequest()
        
        verifyCounts()
        queue.store(request: request)
        verifyCounts(["user": 1])
    }
    
    func test_storingUnknownModels() {
        let request = getNotTrackedClassRequest()
        
        verifyCounts()
        queue.store(request: request)
        verifyCounts()
    }
    
    func test_removingKnownModels() {
        // Setup
        let requestA = getUserRequest()
        let requestB = getUserRequest()
        
        queue.store(request: requestA)
        queue.store(request: requestB)
        verifyCounts(["user": 2])
        
        // Test
        queue.remove(request: requestA)
        verifyCounts(["user": 1])
        let remainingKey = Array(queue.activeUserRequests.keys)[0]
        XCTAssertEqual(remainingKey, requestB.id)
        queue.remove(request: requestB)
        verifyCounts(["user": 0])
    }
    
    func test_removingUnknownModels() {
        let request = getNotTrackedClassRequest()
        
        queue.store(request: request)
        verifyCounts()
        
        // Test (Allowed to remove non-tracked requests)
        queue.remove(request: request)
        verifyCounts()
    }
    
    func test_failingTrackedModels() {
        let request = getUserRequest()
        queue.store(request: request)
        
        let result = queue.markRequestAsFailed(request)
        XCTAssertTrue(result, "Request holds known model. Should have been marked")
        XCTAssertTrue(request.failed)
        XCTAssertEqual(request.failureCount, 1)
    }
    
    func test_failingUnknownModels() {
        let request = getNotTrackedClassRequest()
        queue.store(request: request)
        
        let result = queue.markRequestAsFailed(request)
        XCTAssertFalse(result, "Request holds unknown model. Should not have been marked.")
    }
    
    func test_autofailingTrackedModels() {
        var completionCalled: Bool = false
        var completionError: Error? = nil
        
        let request = getUserRequest()

        let myDelegate = MockDelegate()
        myDelegate.send = {
            XCTFail("Send should not have been called")
        }
        myDelegate.complete = { (data, error) in
            completionCalled = true
            completionError = error
        }
        queue.delegate = myDelegate
        
        queue.store(request: request)
        
        let try1 = queue.markRequestAsFailed(request)
        XCTAssertTrue(try1)
        XCTAssertFalse(completionCalled)
        XCTAssertNil(completionError)
        
        let try2 = queue.markRequestAsFailed(request)
        XCTAssertTrue(try2)
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(completionError as? TimeError, TimeError.authenticationFailure("Maximum number of access failures"))
        
        let try3 = queue.markRequestAsFailed(request)
        XCTAssertFalse(try3, "Failed requests should be removed from the queue")
    }
}
