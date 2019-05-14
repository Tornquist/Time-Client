//
//  CategoriesViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 3/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class CategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var signOutButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    var addButton: UIBarButtonItem!
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
        self.addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPressed(_:)))
        
        let topConstraint = NSLayoutConstraint(item: self.view!, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.refreshNavigation()
    }
    
    func refreshNavigation() {
        self.navigationItem.leftBarButtonItem = self.moving ? self.cancelButton: self.signOutButton
        self.navigationItem.rightBarButtonItem = self.moving ? nil : self.addButton
        self.navigationItem.title = self.moving ? NSLocalizedString("Select Target", comment: "") : nil
    }
    
    // MARK: - Data Methods and Actions
    
    func loadData(refresh: Bool = false) {
        let completion: (Error?) -> Void = { error in
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
        
        Time.shared.store.getCategories(refresh: refresh) { (categories, error) in completion(error) }
        Time.shared.store.getEntries(refresh: refresh) { (entries, error) in completion(error) }
    }
    
    func createAccount() {
        self.showAlertForCreatingANewAccount { (create) in
            guard create else { return }
            
            Time.shared.store.createAccount() { (newAccount, error) in
                guard error == nil && newAccount != nil else {
                    // Invalid State, needs hard data refresh
                    self.loadData(refresh: true)
                    return
                }
                
                DispatchQueue.main.async {
                    self.tableView.performBatchUpdates({
                        // Sections currently sorted by ID -> Always added to end
                        let indexSet = IndexSet(arrayLiteral: Time.shared.store.accountIDs.count - 1)
                        self.tableView.insertSections(indexSet, with: .automatic)
                    }, completion: nil)
                }
            }
        }
    }
    
    func addChildTo(rootOf tree: CategoryTree, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let category = tree.node
        self.showAlertFor(addingChildTo: category) { (name) in
            guard name != nil else { return }
            
            Time.shared.store.addCategory(withName: name!, to: category) { (success, newCategory) in
                DispatchQueue.main.async {
                    if success {
                        let alreadyExpanded = tree.expanded
                        if alreadyExpanded && newCategory != nil, let offset = tree.getOffset(withChild: newCategory!) {
                            self.tableView.performBatchUpdates({
                                let newPath = IndexPath(row: indexPath.row + offset, section: indexPath.section)
                                self.tableView.insertRows(at: [newPath], with: .automatic)
                            }, completion: nil)
                        } else if !alreadyExpanded {
                            tree.toggleExpanded(forceTo: true)
                            let numRows = tree.numberOfDisplayRows()
                            let range: CountableClosedRange = 1...numRows
                            let insertPaths = range.map {
                                IndexPath(row: indexPath.row + $0, section: indexPath.section)
                            }
                            self.tableView.performBatchUpdates({
                                self.tableView.insertRows(at: insertPaths, with: .automatic)
                            }, completion: nil)
                        } else {
                            self.tableView.reloadData()
                        }
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
                    if success,
                        let destinationTree = Time.shared.store.categoryTrees[newParent.accountID],
                        let movedTree = destinationTree.findItem(withID: category.id ) {
                        var parent = movedTree.parent
                        while parent != nil {
                            parent?.toggleExpanded(forceTo: true)
                            parent = parent?.parent
                        }
                    }
                    complete()
                }
            } else {
                complete()
            }
        }
    }
    
    func edit(category: TimeSDK.Category, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
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
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                        completion(success)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    func delete(tree: CategoryTree, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        self.showAlertFor(deleting: tree) { (delete, removeChildren) in
            guard delete else {
                completion(false)
                return
            }

            // Display Properties
            let startingExpanded = tree.expanded
            let startingDisplayCount = tree.numberOfDisplayRows()

            let hasDirectChildren = tree.children.count > 0
            let showingChildren = hasDirectChildren && startingDisplayCount > 0
            
            let parent: CategoryTree? = tree.parent
            let children: [CategoryTree] = tree.children
            var parentRowStart: Int? = nil
            if let offset = tree.parent?.getOffset(withChild: tree.node) {
                parentRowStart = indexPath.row - offset
            }
            
            let parentProperties = parent != nil && parentRowStart != nil
            
            // Determine Actions
            let animateCellOnly = !hasDirectChildren
            let animateAwayChildren = removeChildren && showingChildren
            
            let animateChildren = !removeChildren && parentProperties && hasDirectChildren
            let animateUpHiddenChildren = !startingExpanded && animateChildren
            let animateUpVisibleChildren = startingExpanded && animateChildren
            
            let canAnimate = animateCellOnly || removeChildren || animateUpHiddenChildren || animateUpVisibleChildren
            
            Time.shared.store.deleteCategory(withID: tree.node.id, andChildren: removeChildren, completion: { success in
                DispatchQueue.main.async {
                    guard success && canAnimate else {
                        self.tableView.reloadData()
                        completion(false)
                        return
                    }
                    
                    var cleanAnimation = true
                    self.tableView.performBatchUpdates({
                        // Delete main node
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        completion(true)
                        
                        if animateAwayChildren {
                            let range: CountableClosedRange = 1...startingDisplayCount
                            let childrenPaths = range.map { IndexPath(row: indexPath.row + $0, section: indexPath.section) }
                            self.tableView.deleteRows(at: childrenPaths, with: .automatic)

                        } else if animateUpHiddenChildren {
                            // Insert child nodes in a collapsed state
                            children.forEach({ $0.toggleExpanded(forceTo: false) })
                            let offsets = children.map({ parent!.getOffset(withChild: $0.node) })
                            let allFound = offsets.reduce(true, { $0 && ($1 != nil) })
                            guard allFound else { cleanAnimation = false; return }
                            
                            let insertPaths = offsets.map({ IndexPath(row: parentRowStart! + $0!, section: indexPath.section) })
                            self.tableView.insertRows(at: insertPaths, with: .automatic)

                        } else if animateUpVisibleChildren {
                            
                            let currentDisplayRows = parent!.numberOfDisplayRows()
                            let range: CountableClosedRange = 1...currentDisplayRows
                            let updatePaths = range.map { i -> IndexPath in
                                // While in batch update, index paths will be offset. Shift to avoid hitting
                                // path being deleted. Following this block, the +1 is no longer needed.
                                var row = parentRowStart! + i
                                if row >= indexPath.row { row = row + 1 }
                                return IndexPath(row: row, section: indexPath.section)
                            }
                            self.tableView.reloadRows(at: updatePaths, with: .automatic)
                        }
                    }, completion: { _ in
                        if !cleanAnimation {
                            self.tableView.reloadData()
                        }
                    })
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
    
    @IBAction func addPressed(_ sender: Any) {
        self.createAccount()
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
        return tree.numberOfDisplayRows(overrideExpanded: self.moving, includeRoot: true)
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
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let categoryTree = self.getTree(for: indexPath) else { return nil }
        let category = categoryTree.node
        
        let isRoot = category.parentID == nil
        
        let editTitle = NSLocalizedString("Edit", comment: "")
        let edit = UIContextualAction(style: .normal, title: editTitle, handler: { (action, view, completion) in
            self.edit(category: category, at: indexPath, completion: completion)
        })
        
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        let delete = UIContextualAction(style: .destructive, title: deleteTitle, handler: { (action, view, completion) in
            self.delete(tree: categoryTree, at: indexPath, completion: completion)
        })
        
        let addTitle = NSLocalizedString("Add", comment: "")
        let add = UIContextualAction(style: .normal, title: addTitle, handler: { (action, view, completion) in
            self.addChildTo(rootOf: categoryTree, at: indexPath, completion: completion)
        })
        
        let config = UISwipeActionsConfiguration(actions: isRoot ? [add] : [add, edit, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let categoryTree = self.getTree(for: indexPath) else { return nil }
        let category = categoryTree.node
        
        let isRoot = category.parentID == nil
        guard !isRoot else { return UISwipeActionsConfiguration(actions: []) }

        let startTitle = NSLocalizedString("Start", comment: "")
        let stopTitle = NSLocalizedString("Stop", comment: "")
        let isOpen = Time.shared.store.isRangeOpen(for: category)
        let performStart = isOpen == false
        let startStopTitle = performStart ? startTitle : stopTitle
        let startStop = UIContextualAction(style: .normal, title: startStopTitle, handler: { (action, view, completion) in
            Time.shared.store.toggleRange(for: category) { (success) in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        })
        
        let recordTitle = NSLocalizedString("Record", comment: "")
        let record = UIContextualAction(style: .normal, title: recordTitle, handler: { (action, view, completion) in
            Time.shared.store.recordEvent(for: category) { (success) in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        })
        
        let config = UISwipeActionsConfiguration(actions: isOpen != nil ? [startStop, record] : [record])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let categoryTree = self.getTree(for: indexPath) else { return }
        
        if self.moving {
            guard Time.shared.store.canMove(self.movingCategory!, to: categoryTree.node) else { return }
            self.move(category: self.movingCategory!, to: categoryTree.node)
        } else {
            let startingDisplayRows = categoryTree.numberOfDisplayRows()
            categoryTree.toggleExpanded()
            let endingDisplayRows = categoryTree.numberOfDisplayRows()
            
            guard startingDisplayRows != endingDisplayRows else { return }
            
            let impact = max(startingDisplayRows, endingDisplayRows)
            let range: CountableClosedRange = 1...impact
            let modifyPaths = range.map {
                IndexPath(row: indexPath.row + $0, section: indexPath.section)
            }
            
            self.tableView.performBatchUpdates({
                if startingDisplayRows > endingDisplayRows {
                    self.tableView.deleteRows(at: modifyPaths, with: .automatic)
                } else {
                    self.tableView.insertRows(at: modifyPaths, with: .automatic)
                }
            }, completion: nil)
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
