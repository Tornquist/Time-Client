//
//  HomeViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 3/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var signOutButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    var moving: Bool { return self.movingCategory != nil }
    var movingCategory: TimeSDK.Category? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureTheme()
        self.loadData()
    }
    
    func configureTheme() {
        self.signOutButton = UIBarButtonItem(title: NSLocalizedString("Sign Out", comment: ""), style: .plain, target: self, action: #selector(signOutPressed(_:)))
        self.cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed(_:)))
        
        let topConstraint = NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.refreshNavigation()
    }
    
    func refreshNavigation() {
        self.navigationItem.leftBarButtonItem = self.moving ? self.cancelButton: self.signOutButton
        self.navigationItem.title = self.moving ? NSLocalizedString("Select Target", comment: "") : nil
    }
    
    // MARK: - Data Methods and Actions
    
    func loadData(refresh: Bool = false) {
        Time.shared.store.getCategories(refresh: true) { (categories, error) in
            guard error == nil else {
                // Show error
                return
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    func addChildTo(category: TimeSDK.Category, completion: @escaping (Bool) -> Void) {
        self.showAlertFor(addingChildTo: category) { (name) in
            guard name != nil else { return }
            
            Time.shared.store.addCategory(withName: name!, to: category) { (success) in
                // Need to update specific rows for clean animation out of swipe gesture
                DispatchQueue.main.async {
                    if success {
                        // self.tableView.beginUpdates()
                        // self.tableView.insertRows(at: [IndexPath(row: Time.shared.store.categories.count-1, section: 0)], with: .automatic)
                        // self.tableView.endUpdates()
                        self.tableView.reloadData()
                    }
                    completion(success)
                }
            }
        }
    }
    
    func move(category: TimeSDK.Category, to newParent: TimeSDK.Category) {
        self.showAlertFor(confirmingMoveOf: category, to: newParent) { (confirmed) in
            let complete = {
                self.movingCategory = nil
                DispatchQueue.main.async {
                    self.refreshNavigation()
                    self.tableView.reloadData()
                }
            }
            
            if confirmed {
                Time.shared.store.moveCategory(category, to: newParent) { (success) in
                    complete()
                }
            } else {
                complete()
            }
        }
    }
    
    func edit(category: TimeSDK.Category, completion: @escaping (Bool) -> Void) {
        self.showAlertFor(editing: category) { (willMove, newName) in
            if willMove {
                self.movingCategory = category
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshNavigation()
                    completion(true)
                }
            } else if newName != nil {
                Time.shared.store.renameCategory(category, to: newName!) { (success) in
                    DispatchQueue.main.async {
                        if (success) {
                            self.tableView.reloadData()
                        }
                        completion(success)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    func delete(tree: CategoryTree, completion: @escaping (Bool) -> Void) {
        self.showAlertFor(deleting: tree) { (delete, andChildren) in
            guard delete else {
                completion(false)
                return
            }

            Time.shared.store.deleteCategory(withID: tree.node.id, andChildren: andChildren, completion: { success in
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    completion(false)
                }
            })
        }
    }
    
    // MARK: - Events
    
    @IBAction func signOutPressed(_ sender: Any) {
        Time.shared.deauthenticate()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.movingCategory = nil
        self.refreshNavigation()
        self.tableView.reloadData()
    }
    
    // MARK: - Table View
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.loadData(refresh: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Time.shared.store.accountIDs.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tree = self.getTree(for: section) else { return 0 }
        return tree.numberOfDisplayRows(overrideExpanded: self.moving)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let categoryTree = self.getTree(for: indexPath) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
            cell.textLabel?.text = "ERROR"
            cell.detailTextLabel?.text = "ERROR"
            return cell
        }
        let category = categoryTree.node
        
        var backgroundColor: UIColor = .white
        if self.moving {
            let isValidTarget = Time.shared.store.canMove(self.movingCategory!, to: category)
            let isSelf = self.movingCategory?.id == category.id
            backgroundColor = isSelf ? .green : (isValidTarget ? .white : .lightGray)
        }
        
        if category.parentID == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
            cell.textLabel?.text = "ACCOUNT \(category.accountID)"
            cell.backgroundColor = backgroundColor
            return cell
        }
            
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let displayDepth = categoryTree.depth - 1 // Will not show account cell
        let padding = String(repeating: "    ", count: displayDepth)
        cell.textLabel?.text = "\(category.id)"
        cell.detailTextLabel?.text = padding + category.name
        cell.backgroundColor = backgroundColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let categoryTree = self.getTree(for: indexPath) else { return nil }
        let category = categoryTree.node
        
        let isRoot = category.parentID == nil
        
        let edit = UIContextualAction(style: .normal, title: "Edit", handler: { (action, view, completion) in
            self.edit(category: category, completion: completion)
        })
        
        let delete = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, completion) in
            self.delete(tree: categoryTree, completion: completion)
        })
        
        let add = UIContextualAction(style: .normal, title: "Add", handler: { (action, view, completion) in
            self.addChildTo(category: category, completion: completion)
        })
        
        let config = UISwipeActionsConfiguration(actions: isRoot ? [add] : [add, edit, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let categoryTree = self.getTree(for: indexPath) else { return }
        
        if !self.moving {
            categoryTree.toggleExpanded()
            self.tableView.reloadData()
        } else {
            guard Time.shared.store.canMove(self.movingCategory!, to: categoryTree.node) else { return }
            self.move(category: self.movingCategory!, to: categoryTree.node)
        }
    }
    
    // MARK: - TableView <-> Data store support methods
    
    func getTree(for section: Int) -> CategoryTree? {
        guard section < Time.shared.store.accountIDs.count else { return nil }
        let accountID = Time.shared.store.accountIDs[section]
        guard let tree = Time.shared.store.categoryTrees[accountID] else { return nil }
        
        return tree
    }
    
    func getTree(for indexPath: IndexPath) -> CategoryTree? {
        guard let tree = self.getTree(for: indexPath.section) else { return nil }
        return tree.getChild(withOffset: indexPath.row, overrideExpanded: self.moving)
    }
}
