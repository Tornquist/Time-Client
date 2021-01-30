//
//  EntriesViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/14/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import SwiftUI
import TimeSDK

class EntriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EntryTableViewCellDelegate {
    
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    var entries: [Entry] = []

    // +Alerts Support
    var pickerData: [(String,Any?)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTheme()
        
        NotificationCenter.default.addObserver(self, selector: #selector(safeReload), name: .TimeBackgroundStoreUpdate, object: nil)
        
        let entryNib = UINib(nibName: EntryTableViewCell.nibName, bundle: nil)
        self.tableView.register(entryNib, forCellReuseIdentifier: EntryTableViewCell.reuseID)
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 63.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    func configureTheme() {
        let topConstraint = NSLayoutConstraint(item: self.view!, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.refreshNavigation()
    }
    
    func refreshNavigation() {
        self.navigationItem.title = NSLocalizedString("Entries", comment: "")
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
        
        let networkMode: Store.NetworkMode = refresh ? .refreshAll : .asNeeded
        Time.shared.store.getCategories(networkMode) { (categories, error) in categoriesDone = true; completion(error) }
        Time.shared.store.getEntries(networkMode) { (entries, error) in entriesDone = true; completion(error) }
    }
    
    func refreshEntries(reloadTable: Bool = true) {
        let tempEntries = Time.shared.store.entries
        let sortedEntries = tempEntries.sorted { (a, b) -> Bool in
            return a.startedAt > b.startedAt
        }
        self.entries = sortedEntries
        
        guard reloadTable else { return }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func edit(entry: Entry, at indexPath: IndexPath,  completion: @escaping (Bool) -> Void) {
        // Prepare/flatten category data
        let accountIDs = Time.shared.store.accountIDs.sorted()
        let categoryTreesByAccount = accountIDs.compactMap { Time.shared.store.categoryTrees[$0]?.listCategoryTrees() }
        let categories = categoryTreesByAccount.flatMap { (categoryTrees) -> [EntryView.CategoryOption] in
            return categoryTrees.map { (categoryTree) -> EntryView.CategoryOption in
                let isRoot = categoryTree.parent == nil
                let name = isRoot ? "Account \(categoryTree.node.accountID)" : categoryTree.node.name
                return (name: name, depth: categoryTree.depth, categoryID: categoryTree.node.id)
            }
        }
        
        // Prepare timezone list
        let allTimezones = TimeZone.knownTimeZoneIdentifiers
        let timezoneLabels = allTimezones.map({
            $0.replacingOccurrences(of: "/", with: " > ")
                .replacingOccurrences(of: "_", with: " ")
        })
        let timezoneValues = allTimezones
        let timezones = Array(zip(timezoneLabels, timezoneValues))

        var editView = EntryView(entry, timezones: timezones, categories: categories)
        
        editView.presentingVC = self
        editView.save = { newEntry in
            
            let changedCategory = entry.categoryID != newEntry.categoryID
            let changedType = entry.type != newEntry.type
            let changedStartedAt = entry.startedAt != newEntry.startedAt
            let changedStartedAtTimezone = entry.startedAtTimezone != newEntry.startedAtTimezone
            let changedEndedAt = entry.endedAt != newEntry.endedAt
            let changedEndedAtTimezone = entry.endedAtTimezone != newEntry.endedAtTimezone
                        
            let someChanged = changedCategory || changedType || changedStartedAt || changedStartedAtTimezone || changedEndedAt || changedEndedAtTimezone
            guard someChanged else {
                return
            }
            
            let newCategory = changedCategory
                ? Time.shared.store.categories.first(where: { $0.id == newEntry.categoryID })
                : nil
            
            Time.shared.store.update(
                entry: entry,
                setCategory: newCategory,
                setType: changedType ? newEntry.type : nil,
                setStartedAt: changedStartedAt ? newEntry.startedAt : nil,
                setStartedAtTimezone: changedStartedAtTimezone ? newEntry.startedAtTimezone : nil,
                setEndedAt: changedEndedAt ? newEntry.endedAt : nil,
                setEndedAtTimezone: changedEndedAtTimezone ? newEntry.endedAtTimezone : nil
            ) { (success) in
                DispatchQueue.main.async {
                    if changedStartedAt {
                        self.refreshEntries() // Re-sort
                        self.tableView.reloadData()
                    } else {
                        self.tableView.reloadRows(at: [indexPath], with: .right)
                    }
                }
            }
        }
        
        let editVC = UIHostingController(rootView: editView)
        self.present(editVC, animated: true, completion: {
            // Hide swipe over
            completion(true)
        })
    }
    
    func stop(entry: Entry, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        Time.shared.store.stop(entry: entry) { (success) in
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [indexPath], with: .right)
                completion(false)
            }
        }
    }
    
    func delete(entry: Entry, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        self.showAlertFor(deleting: entry) { (delete) in
            guard delete else { completion(false); return }
            
            Time.shared.store.delete(entry: entry) { deleted in
                self.refreshEntries(reloadTable: false)
                DispatchQueue.main.async {
                    if deleted {
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                    completion(deleted)
                }
            }
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: EntryTableViewCell.reuseID, for: indexPath) as! EntryTableViewCell
        let entry = self.entries[indexPath.row]
        
        cell.configure(for: entry)
        cell.delegate = self
        cell.backgroundColor = .systemBackground
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = self.entries[indexPath.row]
        
        let editTitle = NSLocalizedString("Edit", comment: "")
        let edit = UIContextualAction(style: .normal, title: editTitle, handler: { (action, view, completion) in
            self.edit(entry: entry, at: indexPath, completion: completion)
        })
        
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        let delete = UIContextualAction(style: .destructive, title: deleteTitle, handler: { (action, view, completion) in
            self.delete(entry: entry, at: indexPath, completion: completion)
        })

        let config = UISwipeActionsConfiguration(actions: [delete, edit])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
        
    @objc func safeReload() {
        if Thread.isMainThread {
            self.tableView.reloadData()
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - EntryTableViewCellDelegate
    
    func stop(entryID: Int, sender: EntryTableViewCell) {
        guard let entry = self.entries.first(where: { $0.id == entryID }) else { return }
        
        Time.shared.store.stop(entry: entry) { (success) in
            DispatchQueue.main.async {
                if let indexPath = self.tableView.indexPath(for: sender) {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                } else {
                    self.safeReload()
                }
            }
        }
    }
}
