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
    var dateFormatters: [String:DateFormatter] = [:]
    
    // +Alerts Support
    var pickerData: [(String,Any?)] = []
    
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
    
    func edit(entry: Entry, at indexPath: IndexPath,  completion: @escaping (Bool) -> Void) {
        self.showAlertFor(editing: entry) { (newCategoryID, newEntryType, newStartDate, newStartTimezone, newEndDate, newEndTimezone) in
            guard newCategoryID != nil || newEntryType != nil || newStartDate != nil || newEndDate != nil || newStartTimezone != nil || newEndTimezone != nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            let newCategory = newCategoryID != nil
                ? Time.shared.store.categories.first(where: { $0.id == newCategoryID! })
                : nil
            Time.shared.store.update(
                entry: entry,
                setCategory: newCategory,
                setType: newEntryType,
                setStartedAt: newStartDate,
                setStartedAtTimezone: newStartTimezone,
                setEndedAt: newEndDate,
                setEndedAtTimezone: newEndTimezone
            ) { (success) in
                DispatchQueue.main.async {
                    if newStartDate != nil {
                        self.refreshEntries() // Re-sort
                        self.tableView.reloadData()
                    } else {
                        self.tableView.reloadRows(at: [indexPath], with: .right)
                    }
                    completion(false)
                }
            }
        }
    }
    
    func stop(entry: Entry, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        Time.shared.store.stop(entry: entry) { (success) in
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [indexPath], with: .right)
                completion(false)
            }
        }
    }
    
    func delete(entry: Entry, completion: @escaping (Bool) -> Void) {
        self.showAlertFor(deleting: entry) { (delete) in
            guard delete else { completion(false); return }
            
            Time.shared.store.delete(entry: entry) { deleted in
                DispatchQueue.main.async {
                    completion(delete)
                }
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
        let timeText = self.getTimeString(for: entry)
        
        cell.textLabel?.text = displayName
        cell.detailTextLabel?.text = timeText
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = self.entries[indexPath.row]
        
        let editTitle = NSLocalizedString("Edit", comment: "")
        let edit = UIContextualAction(style: .normal, title: editTitle, handler: { (action, view, completion) in
            self.edit(entry: entry, at: indexPath, completion: completion)
        })
        
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        let delete = UIContextualAction(style: .destructive, title: deleteTitle, handler: { (action, view, completion) in
            self.delete(entry: entry, completion: completion)
        })

        let config = UISwipeActionsConfiguration(actions: [edit, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = self.entries[indexPath.row]
        
        let stopTitle = NSLocalizedString("Stop", comment: "")
        let stop = UIContextualAction(style: .normal, title: stopTitle, handler: { (action, view, completion) in
            self.stop(entry: entry, at: indexPath, completion: completion)
        })
        
        let isRunning = entry.type == .range && entry.endedAt == nil
        
        let config = UISwipeActionsConfiguration(actions: isRunning ? [stop] : [])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    // MARK: - Time Formatting
    
    func getTimeString(for entry: Entry) -> String {
        let startedAtString = self.format(time: entry.startedAt, with: entry.startedAtTimezone)
        let endedAtString = entry.endedAt != nil ? self.format(time: entry.endedAt!, with: entry.endedAtTimezone) : nil
        
        var timeText = ""
        if entry.type == .event {
            timeText = "@ \(startedAtString)"
        } else if entry.endedAt == nil {
            timeText = "\(startedAtString) - \(NSLocalizedString("Present", comment: ""))"
        } else {
            timeText = "\(startedAtString) - \(endedAtString!)"
        }
        return timeText
    }
    
    func format(time: Date, with timezoneIdentifier: String?) -> String {
        let defaultTimezone = TimeZone.autoupdatingCurrent
        let safeTimezone = timezoneIdentifier ?? defaultTimezone.identifier
        if (self.dateFormatters[safeTimezone] == nil) {
            let timezone = TimeZone(identifier: safeTimezone) ?? defaultTimezone
            if (self.dateFormatters[timezone.identifier] == nil) {
                let newFormatter = DateFormatter.init()
                newFormatter.dateFormat = "MM/dd/YY hh:mm a zzz"
                newFormatter.timeZone = timezone
                self.dateFormatters[safeTimezone] = newFormatter
            }
        }
        
        return self.dateFormatters[safeTimezone]!.string(from: time)
    }
}
