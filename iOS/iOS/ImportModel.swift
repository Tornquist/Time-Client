//
//  ImportModel.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/17/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import Foundation
import Combine
import TimeSDK

class ImportModel: ObservableObject {
    
    @Published var warehouse: Warehouse
    
    var requests: [FileImporter.Request] = []
    @Published var isRefreshing: Bool = false
    
    var cancellables = [AnyCancellable]()
    
    init(for warehouse: Warehouse) {
        self.warehouse = warehouse
        
        let c = warehouse.objectWillChange.sink { self.objectWillChange.send() }
        self.cancellables.append(c)

        self.loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didCreateImportRequest), name: .TimeImportRequestCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteImportRequest), name: .TimeImportRequestCompleted, object: nil)
    }
    
    // MARK: - Data Methods and Actions
    
    func loadData(refresh: Bool = false) {
        self.isRefreshing = true
        let networkMode: Store.NetworkMode = refresh ? .refreshAll : .asNeeded
        Time.shared.store.getImportRequests(networkMode) { (requests, error) in
            self.isRefreshing = false
            
            if let requests = requests {
                self.requests = requests.sorted(by: { (a, b) -> Bool in
                    return a.createdAt < b.createdAt
                })
            }

            self.optionallyRepeat()
        }
    }
    
    func optionallyRepeat() {
        let somethingPending = requests.map({ !$0.complete }).reduce(false, { $0 || $1 })
        if somethingPending {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                self.loadData(refresh: true)
            }
        }
    }
    
    // MARK: - Time Notifictions
    
    @objc func didCreateImportRequest() {
        self.loadData()
    }
    
    @objc func didCompleteImportRequest() {
        self.loadData()
        DispatchQueue.main.async {
            self.warehouse.loadData(refresh: true)
        }
    }
}
