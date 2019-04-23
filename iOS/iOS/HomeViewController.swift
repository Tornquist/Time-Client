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
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureTheme()
        self.loadData()
    }
    
    func configureTheme() {
        self.signOutButton = UIBarButtonItem(title: NSLocalizedString("Sign Out", comment: ""), style: .plain, target: self, action: #selector(signOutPressed(_:)))
        self.navigationItem.leftBarButtonItem = self.signOutButton
        
        let topConstraint = NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)
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
        let alert = UIAlertController(title: "Create Category", message: "Under \(category.id)", preferredStyle: .alert)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        
        let create = UIAlertAction(title: "Create", style: .default) { _ -> Void in
            let nameTextField = alert.textFields![0] as UITextField
            let name = nameTextField.text
            guard name != nil && name!.count > 0 else {
                completion(false)
                return
            }
            
            Time.shared.store.addCategory(withName: name!, to: category) { (success) in
                // Need to update specific rows for clean animation out of swipe gesture
                DispatchQueue.main.async {
                    if success {
//                        self.tableView.beginUpdates()
//                        self.tableView.insertRows(at: [IndexPath(row: Time.shared.store.categories.count-1, section: 0)], with: .automatic)
//                        self.tableView.endUpdates()
                        self.tableView.reloadData()
                    }
                    completion(success)
                }
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completion(false) })
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
    
    // MARK: - Events
    
    @IBAction func signOutPressed(_ sender: Any) {
        Time.shared.deauthenticate()
        self.dismiss(animated: true, completion: nil)
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
        return tree.numChildren + 1 // Add node for account
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let category = self.getCategory(for: indexPath) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
            cell.textLabel?.text = "ERROR"
            cell.detailTextLabel?.text = "ERROR"
            return cell
        }
        
        if category.parentID == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
            cell.textLabel?.text = "ACCOUNT \(category.accountID)"
            return cell
        }
            
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let trueDepth = self.getTree(for: indexPath.section)?.findItem(withID: category.id)?.depth ?? 1
        let displayDepth = trueDepth - 1 // Will not show account cell
        let padding = String(repeating: "    ", count: displayDepth)
        cell.textLabel?.text = "\(category.id)"
        cell.detailTextLabel?.text = padding + category.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let category = self.getCategory(for: indexPath) else { return nil }
        
        let isRoot = category.parentID == nil
        
        let edit = UIContextualAction(style: .normal, title: "Edit", handler: { (action, view, completion) in
            print("EDIT")
            completion(true)
        })
        
        let delete = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, completion) in
            print("DELETE")
            completion(false)
        })
        
        let add = UIContextualAction(style: .normal, title: "Add", handler: { (action, view, completion) in
            self.addChildTo(category: category, completion: completion)
        })
        
        let config = UISwipeActionsConfiguration(actions: isRoot ? [add] : [add, edit, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: - TableView <-> Data store support methods
    
    func getTree(for section: Int) -> CategoryTree? {
        guard section < Time.shared.store.accountIDs.count else { return nil }
        let accountID = Time.shared.store.accountIDs[section]
        guard let tree = Time.shared.store.categoryTrees[accountID] else { return nil }
        
        return tree
    }
    
    func getCategory(for indexPath: IndexPath) -> TimeSDK.Category? {
        guard let tree = self.getTree(for: indexPath.section) else {
            return nil
        }
        
        // Starts with Root
        if indexPath.row == 0 { return tree.node }
        
        let category = tree.getChild(withOffset: indexPath.row - 1)
        return category
    }
}
