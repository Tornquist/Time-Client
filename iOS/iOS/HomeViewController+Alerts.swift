//
//  HomeViewController+Alerts.swift
//  iOS
//
//  Created by Nathan Tornquist on 4/29/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

extension HomeViewController {
    func showAlertFor(addingChildTo category: TimeSDK.Category, completion: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "Create Category", message: "Under \(category.id)", preferredStyle: .alert)
        
        let create = UIAlertAction(title: "Create", style: .default) { _ -> Void in
            let nameTextField = alert.textFields![0] as UITextField
            let name = nameTextField.text
            guard name != nil && name!.count > 0 else {
                completion(nil)
                return
            }
            
            completion(name)
        }
        create.isEnabled = false
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                create.isEnabled = textField.text?.count ?? 0 > 0
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completion(nil) })
        alert.addAction(create)
        alert.addAction(cancel)
        
        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showAlertFor(confirmingMoveOf category: TimeSDK.Category, to newParent: TimeSDK.Category, completion: @escaping (Bool) -> Void) {
        let title = NSLocalizedString("Confirm Move", comment: "")
        let destinationDescription = newParent.parentID != nil ? newParent.name : NSLocalizedString("Account \(newParent.accountID)", comment: "")
        let description = NSLocalizedString("Are you sure you wish to move \"\(category.name)\" to \"\(destinationDescription)\"?", comment: "")
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Move", comment: ""), style: .default, handler: { _ in
            completion(true)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
            completion(false)
        }))
        
        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showAlertFor(editing category: TimeSDK.Category, completion: @escaping (Bool, String?) -> Void) {
        let moveTitle = NSLocalizedString("Move Item", comment: "")
        let moveDescription = NSLocalizedString("Select a destination.\n\nMoving a category will also move its children. Moving to a new account may change access permissions.", comment: "")
        let moveAlert = UIAlertController(title: moveTitle, message: moveDescription, preferredStyle: .alert)
        moveAlert.addAction(UIAlertAction(title: NSLocalizedString("Select Destination", comment: ""), style: .default, handler: { _ in
            completion(true, nil)
        }))
        moveAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in completion(false, nil) }))
        
        let renameTitle = NSLocalizedString("Rename Item", comment: "")
        let renameDescription = NSLocalizedString("Enter a new name for \"\(category.name)\"", comment: "")
        let renameAlert = UIAlertController(title: renameTitle, message: renameDescription, preferredStyle: .alert)
        let renameConfirmAction = UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .default) { _ -> Void in
            let nameTextField = renameAlert.textFields![0] as UITextField
            let name = nameTextField.text
            guard name != nil && name!.count > 0 else {
                completion(false, nil)
                return
            }
            
            completion(false, name)
        }
        renameConfirmAction.isEnabled = false
        
        let renameCancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in completion(false, nil) })
        renameAlert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "New Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                renameConfirmAction.isEnabled = textField.text?.count ?? 0 > 0
            }
        }
        renameAlert.addAction(renameConfirmAction)
        renameAlert.addAction(renameCancelAction)
        
        let editTitle = NSLocalizedString("Edit \"\(category.name)\"", comment: "")
        let editMenuAlert = UIAlertController(title: editTitle, message: nil, preferredStyle: .alert)
        editMenuAlert.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { _ in
            if Thread.current.isMainThread {
                self.present(renameAlert, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    self.present(renameAlert, animated: true, completion: nil)
                }
            }
        }))
        editMenuAlert.addAction(UIAlertAction(title: NSLocalizedString("Move", comment: ""), style: .default, handler: { _ in
            if Thread.current.isMainThread {
                self.present(moveAlert, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    self.present(moveAlert, animated: true, completion: nil)
                }
            }
        }))
        editMenuAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in completion(false, nil) }))
        
        if Thread.current.isMainThread {
            self.present(editMenuAlert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(editMenuAlert, animated: true, completion: nil)
            }
        }
    }
    
    func showAlertFor(deleting tree: CategoryTree, completion: @escaping (Bool, Bool) -> Void) {
        let category = tree.node
        
        // Initial Question
        let startingTitle = NSLocalizedString("Delete", comment: "")
        let startingMessage = NSLocalizedString("Are you sure you wish to remove the category \"\(category.name)\"?\n\nAny entries attached to deleted categories will also be removed.", comment: "")
        
        let deleteCategoryText = NSLocalizedString("Delete Selected Category", comment: "")
        let deleteCategoryAndChildrenText = NSLocalizedString("Delete Category and Children", comment: "")
        let cancelText = NSLocalizedString("Cancel", comment: "")
        
        // Confirmation Support
        let confirmAction = { (all: Bool) in
            let deleteTitle = NSLocalizedString("Confirm Delete", comment: "")
            let confirmText = NSLocalizedString("Delete", comment: "")
            let cancelText = NSLocalizedString("Cancel", comment: "")
            
            let entriesOnCategory = all ? 0 : 0 // Needs to dynamically build based on children
            let entriesPlural = entriesOnCategory == 1 ? NSLocalizedString("entry", comment: "") : NSLocalizedString("entries", comment: "")
            
            let numChildren = tree.children.count
            let childrenPlural = numChildren == 1 ? NSLocalizedString("child", comment: "") : NSLocalizedString("children", comment: "")
            
            let deleteSelectedMainMessage = NSLocalizedString("Category \"\(category.name)\" will be removed.", comment: "")
            let deleteAllMainMessage = NSLocalizedString("Category \"\(category.name)\" and its children will be removed.", comment: "")
            
            let entryMessage = NSLocalizedString("\(entriesOnCategory) \(entriesPlural) will be removed.", comment: "")
            let childrenMessage = NSLocalizedString("\(numChildren) \(childrenPlural) will be reassigned to the parent of \"\(category.name)\"", comment: "")
            
            var actionMessage: [String] = []
            actionMessage.append(all ? deleteAllMainMessage : deleteSelectedMainMessage)
            actionMessage.append(entryMessage)
            if !all { actionMessage.append(childrenMessage) }
            let deleteMessage = actionMessage.joined(separator: "\n\n")
            
            let trueAction = { completion(true, all) }
            
            let alert = UIAlertController(title: deleteTitle, message: deleteMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: confirmText, style: .destructive, handler: { _ in trueAction() }))
            alert.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { _ in completion(false, false) }))
            
            if Thread.current.isMainThread {
                self.present(alert, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        // Initial Alert
        let startingAlert = UIAlertController(title: startingTitle, message: startingMessage, preferredStyle: .alert)
        let deleteCategory = UIAlertAction(title: deleteCategoryText, style: .destructive, handler: { _ in confirmAction(false) })
        let deleteCategoryAndChildren = UIAlertAction(title: deleteCategoryAndChildrenText, style: .destructive, handler: { _ in confirmAction(true) })
        let cancelAll = UIAlertAction(title: cancelText, style: .cancel, handler: { _ in completion(false, false) })
        startingAlert.addAction(deleteCategory)
        startingAlert.addAction(deleteCategoryAndChildren)
        startingAlert.addAction(cancelAll)
        
        if Thread.current.isMainThread {
            self.present(startingAlert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(startingAlert, animated: true, completion: nil)
            }
        }
    }
}
