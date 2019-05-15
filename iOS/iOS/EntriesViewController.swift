//
//  EntriesViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class EntriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var signOutButton: UIBarButtonItem!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    var entries: [Entry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    func configureTheme() {
        self.signOutButton = UIBarButtonItem(title: NSLocalizedString("Sign Out", comment: ""), style: .plain, target: self, action: #selector(signOutPressed(_:)))
        
        let topConstraint = NSLayoutConstraint(item: self.view!, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.refreshNavigation()
    }
    
    func refreshNavigation() {
        self.navigationItem.leftBarButtonItem = self.signOutButton
    }
    
    // MARK: - Data Methods and Actions
    
    func loadData(refresh: Bool = false) {
        var categoriesDone = false
        var entriesDone = false
        
        let completion: (Error?) -> Void = { error in
            // TODO: Show errors as-needed
            if categoriesDone && entriesDone {
                self.refreshEntries()
                
                DispatchQueue.main.async {
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                }
            }
        }
        
        Time.shared.store.getCategories(refresh: refresh) { (categories, error) in categoriesDone = true; completion(error) }
        Time.shared.store.getEntries(refresh: refresh) { (entries, error) in entriesDone = true; completion(error) }
    }
    
    func refreshEntries() {
        let tempEntries = Time.shared.store.entries
        let sortedEntries = tempEntries.sorted { (a, b) -> Bool in
            return a.startedAt > b.startedAt
        }
        self.entries = sortedEntries
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell", for: indexPath)
        let entry = self.entries[indexPath.row]
        
        guard
            let category = Time.shared.store.categories.first(where: { $0.id == entry.categoryID }),
            let accountTree = Time.shared.store.categoryTrees[category.accountID],
            let categoryTree = accountTree.findItem(withID: category.id)
        else {
            let errorText = NSLocalizedString("Error", comment: "")
            cell.textLabel?.text = errorText
            cell.detailTextLabel?.text = errorText
            return cell
        }
        
        var displayNameParts = [categoryTree.node.name]
        var position = categoryTree.parent
        while position != nil {
            // Make sure exists and is not root
            if position != nil && position?.parent != nil {
                displayNameParts.append(position!.node.name)
            }
            position = position?.parent
        }
        
        let displayName = displayNameParts.reversed().joined(separator: " > ")
        
        var timeText = ""
        if entry.type == .event {
            timeText = "@ \(entry.startedAt)"
        } else if entry.endedAt == nil {
            timeText = "\(entry.startedAt) - \(NSLocalizedString("Present", comment: ""))"
        } else {
            timeText = "\(entry.startedAt) - \(entry.endedAt!)"
        }
        
        cell.textLabel?.text = displayName
        cell.detailTextLabel?.text = timeText
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
