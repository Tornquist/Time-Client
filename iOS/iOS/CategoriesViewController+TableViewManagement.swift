//
//  CategoriesViewController+TableViewManagement.swift
//  iOS
//
//  Created by Nathan Tornquist on 6/21/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import Foundation
import TimeSDK

extension CategoriesViewController {
    
    enum SectionType {
        case control(Int)
        case account(Int)
        case moreControls
    }
    
    // MARK: - Table View Data Helpers
    
    // MARK: Controls
    
    func getHeaderSections() -> [ControlType] {
        return self.headerControls
    }
    
    fileprivate func getNumHeaderSections() -> Int {
        return self.getHeaderSections().count
    }
    
    fileprivate func getRecents() -> [CategoryTree] {
        return self.recentCategories
    }
        
    // MARK: Body
    
    fileprivate func getNumBodySections() -> Int {
        return Time.shared.store.accountIDs.count
    }
    
    // MARK: Footer
    
    fileprivate func getNumFooterSections() -> Int {
        return self.footerControls.count > 0 ? 1 : 0
    }
    
    // MARK: - Table View Row and Section Identification
    
    func getNumberOfSections() -> Int {
        let headerSections = self.getNumHeaderSections()
        let bodySections = self.getNumBodySections()
        let footerSections = self.getNumFooterSections()
        
        return headerSections + bodySections + footerSections
    }
    
    func getTypeFor(section: Int) -> SectionType {
        let numHeaderSections = self.getNumHeaderSections()
        let numBodySections = self.getNumBodySections()
        
        if section < numHeaderSections {
            return .control(section)
        }
        if section < numHeaderSections + numBodySections {
            return .account(section - numHeaderSections)
        }
        return .moreControls
    }
    
    func getTitleFor(type sectionType: SectionType) -> String? {
        switch sectionType {
            case .control(let controlId):
                return self.getHeaderSections()[controlId].title
            case .account(let accountOffset):
                return accountOffset == 0
                    ? NSLocalizedString("Accounts", comment: "")
                    : nil
            case .moreControls:
                return nil
        }
    }
    
    func getRowsFor(type sectionType: SectionType) -> Int {
        switch sectionType {
            case .control(let controlId):
                let controlType = self.headerControls[controlId]
                guard controlType != .recents else {
                    return self.getRecents().count
                }
                guard let rows = self.controlRows[controlType] else { return 0 }
                return rows
            case .account(let accountOffset):
                guard let tree = self.getTree(forAdjusted: accountOffset) else { return 0 }
                return tree.numberOfDisplayRows(overrideExpanded: self.moving, includeRoot: true)
            case .moreControls:
                let header = 1
                let controls = self.expandFooterControls ? self.footerControls.count : 0
                return header + controls
        }
    }
    
    // MARK: - Cell-Specific Methods
    
    func getRecentData(forRow row: Int) -> (CategoryTree, Bool) {
        // TODO: Calculate recents in TimeSDK
        let maxDays = 7 // TODO: Merge with recent calculations
        
        let categoryTree = self.getRecents()[row]
        let categoryID = categoryTree.node.id
        
        let cutoff = Date().addingTimeInterval(Double(-maxDays * 24 * 60 * 60))
        let matchingEntry = Time.shared.store.entries
            .filter({ (entry) -> Bool in
                return entry.categoryID == categoryID && entry.startedAt > cutoff
            })
            .sorted(by: { (a, b) -> Bool in
                return a.startedAt > b.startedAt
            }).first
        let isOpen = self.openCategoryIDs.contains(categoryID)

        let isRange = isOpen || matchingEntry?.type == .range
        
        return (categoryTree, isRange)
    }
}
