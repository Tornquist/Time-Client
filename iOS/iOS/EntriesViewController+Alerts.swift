//
//  EntriesViewController+Alerts.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/28/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

extension EntriesViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Edit Tree
    
    func showAlertFor(editing entry: Entry, completion: @escaping (Int?, EntryType?, Date?, Date?) -> Void) {
        let category = Time.shared.store.categories.first(where: { $0.id == entry.categoryID })
        let type = entry.type.rawValue.capitalized
        let title = category != nil
            ? NSLocalizedString("Edit \(type) on \(category!.name)", comment: "")
            : NSLocalizedString("Edit \(type)", comment: "")
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let moveTitle = NSLocalizedString("Move to new category", comment: "")
        let moveAction = UIAlertAction(title: moveTitle, style: .default, handler: { _ in
            self.showAlertFor(moving: entry, completion: completion)
        })
        
        let changeTargetName = (entry.type == .range ? EntryType.event : EntryType.range).rawValue
        let changeTitle = NSLocalizedString("Convert to \(changeTargetName)", comment: "")
        let changeAction = UIAlertAction(title: changeTitle, style: .default, handler: { _ in
            let newType: EntryType = entry.type == .range ? .event : .range
            completion(nil, newType, nil, nil)
        })
        
        let updateStartTitle = NSLocalizedString("Update \(entry.type == .range ? "start" : "event") time", comment: "")
        let updateStartAction = UIAlertAction(title: updateStartTitle, style: .default) { _ in
            self.showAlertFor(updating: entry, startTime: true, completion: completion)
        }
        
        let updateEndTitle = NSLocalizedString("Update end time", comment: "")
        let updateEndAction = UIAlertAction(title: updateEndTitle, style: .default) { _ in
            self.showAlertFor(updating: entry, startTime: false, completion: completion)
        }
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            completion(nil, nil, nil, nil)
        }
        
        alert.addAction(moveAction)
        alert.addAction(changeAction)
        alert.addAction(updateStartAction)
        if entry.type == .range && entry.endedAt != nil {
            alert.addAction(updateEndAction)
        }
        alert.addAction(cancelAction)
        
        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func showAlertFor(moving entry: Entry, completion: @escaping (Int?, EntryType?, Date?, Date?) -> Void) {
        let title = NSLocalizedString("Move entry to:", comment: "")
        let message = "\n\n\n\n\n\n" // Replace with custom view
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let picker = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 140))
        self.categoryPickerData = self.generateCategoryPickerData()
        picker.delegate = self
        picker.dataSource = self
        alert.view.addSubview(picker)
        if let startingIndex = self.categoryPickerData.firstIndex(where: { (object) -> Bool in
            return (object.1 as? CategoryTree)?.node.id == entry.categoryID
            }) {
            picker.selectRow(startingIndex, inComponent: 0, animated: false)
        }

        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            completion(nil, nil, nil, nil)
        }
        let moveTitle = NSLocalizedString("Move", comment: "")
        let moveAction = UIAlertAction(title: moveTitle, style: .default) { _ in
            let row = picker.selectedRow(inComponent: 0)
            let item = self.categoryPickerData[row]
            let tree = item.1 as? CategoryTree
            let categoryID = tree?.node.id
            completion(categoryID, nil, nil, nil)
        }
        
        alert.addAction(moveAction)
        alert.addAction(cancelAction)
        
        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func showAlertFor(updating entry: Entry, startTime: Bool, completion: @escaping (Int?, EntryType?, Date?, Date?) -> Void) {
        
        let changeEventTitle = NSLocalizedString("Change event time", comment: "")
        let changeStartTitle = NSLocalizedString("Change start time", comment: "")
        let changeEndTitle = NSLocalizedString("Change end time", comment: "")
        
        let title = entry.type == .event ? changeEventTitle : (startTime ? changeStartTitle : changeEndTitle)
        let message = "\n\n\n\n\n\n\n" // Replace with custom view
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let picker = UIDatePicker(frame: CGRect(x: 5, y: 30, width: 250, height: 160))
        picker.timeZone = (
            startTime
                ? (entry.startedAtTimezone != nil ? TimeZone(identifier: entry.startedAtTimezone!) : nil)
                : (entry.endedAtTimezone != nil ? TimeZone(identifier: entry.endedAtTimezone!) : nil)
            ) ?? TimeZone.autoupdatingCurrent
        picker.date = startTime ? entry.startedAt : entry.endedAt ?? Date()
        alert.view.addSubview(picker)
        if !startTime { picker.minimumDate = entry.startedAt }
        if startTime && entry.endedAt != nil { picker.maximumDate = entry.endedAt }
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            completion(nil, nil, nil, nil)
        }
        let moveTitle = NSLocalizedString("Move", comment: "")
        let moveAction = UIAlertAction(title: moveTitle, style: .default) { _ in
            startTime ? completion(nil, nil, picker.date, nil) : completion(nil, nil, nil, picker.date)
        }
        
        alert.addAction(moveAction)
        alert.addAction(cancelAction)
        
        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func generateCategoryPickerData() -> [(String, Any?)] {
        let accountIDs = Time.shared.store.accountIDs.sorted()
        let nodeCounts = accountIDs.map({
            Time.shared.store.categoryTrees[$0]?.numberOfDisplayRows(overrideExpanded: true, includeRoot: true)
        })
        let nodes: [[CategoryTree?]] = nodeCounts.enumerated().map { (i, count) in
            guard count != nil else { return [] }
            let range = 0..<count!
            return range.map({ (j) -> CategoryTree? in
                return Time.shared.store.categoryTrees[accountIDs[i]]?.getChild(withOffset: j, overrideExpanded: true)
            })
        }
        let pickerData = nodes.flatMap { (accountTree) -> [(String, CategoryTree?)] in
            return accountTree.map({ (node) -> (String, CategoryTree?) in
                guard node != nil else { return ("", nil) }
                if node != nil && node!.node.parentID == nil {
                    return ("Account \(node!.node.accountID)", node)
                }
                let depth = node?.depth ?? 0
                let spacers = String(repeating: "_", count: depth)
                return (spacers + (node?.node.name ?? ""), node)
            })
        }
        return pickerData.map { (rowData) -> (String, Any?) in
            return (rowData.0, rowData.1 as Any)
        }
    }
    
    // MARK: - Delete
    
    func showAlertFor(deleting entry: Entry, completion: @escaping (Bool) -> Void) {
        let category = Time.shared.store.categories.first(where: { $0.id == entry.categoryID })
        let type = entry.type.rawValue.capitalized
        let title = category != nil
            ? NSLocalizedString("Delete \(type) on \(category!.name)", comment: "")
            : NSLocalizedString("Delete \(type)", comment: "")
        let message = entry.type == .event
            ? NSLocalizedString("Event occurred at \(entry.startedAt.description)", comment: "")
            : NSLocalizedString("Range ran from \(entry.startedAt.description) to \(entry.endedAt != nil ? entry.endedAt!.description : "Present")", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { _ in completion(true) }
        alert.addAction(deleteAction)
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in completion(false) }
        alert.addAction(cancelAction)

        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Picker View
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.categoryPickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.categoryPickerData[row].0
    }
}
