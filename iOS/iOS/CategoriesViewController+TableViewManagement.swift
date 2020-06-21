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
    
    fileprivate func getNumHeaderSections() -> Int {
        return self.headerControls.count
    }
    
    fileprivate func getNumBodySections() -> Int {
        return Time.shared.store.accountIDs.count
    }
    
    fileprivate func getNumFooterSections() -> Int {
        return self.footerControls.count > 0 ? 1 : 0
    }
    
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
    
    func getRowsFor(type sectionType: SectionType) -> Int {
        switch sectionType {
            case .control(let controlId):
                let controlType = self.headerControls[controlId]
                guard controlType != .recents else {
                    return self.recentCategories.count
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
}
