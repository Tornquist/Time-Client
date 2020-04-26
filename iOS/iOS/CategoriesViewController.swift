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
    
    var cancelButton: UIBarButtonItem!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    var moving: Bool { return self.movingCategory != nil }
    var movingCategory: TimeSDK.Category? = nil
    
    enum ControlSectionType: String {
        case metric
        case favorites
        case recents
        case entries
        case signOut
        case importRecords
        case addAccount
        
        var title: String? {
            switch self {
                case .recents:
                    return NSLocalizedString("Recent", comment: "")
                default:
                    return nil
            }
        }
    }
    var controls: [ControlSectionType] = [.recents, .entries]
    let controlRows: [ControlSectionType: Int] = [
        ControlSectionType.entries: 1
    ]
    let moreControls: [ControlSectionType] = [
        .addAccount,
        .importRecords,
        .signOut
    ]
    var expandMoreControls: Bool = false
    
    var recentCategories: [CategoryTree] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTheme()
        
        NotificationCenter.default.addObserver(self, selector: #selector(safeReload), name: .TimeBackgroundStoreUpdate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshNavigation()
        self.loadData()
        
        self.calculateRecents()
    }
    
    func configureTheme() {
        self.cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed(_:)))
        
        let topConstraint = NSLayoutConstraint(item: self.view!, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.view.backgroundColor = self.tableView?.backgroundColor
        
        self.configureTableView()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
                
        self.refreshNavigation()
    }
    
    func configureTableView() {
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
        let detailCellNib = UINib(nibName: DisclosureIndicatorButtonTableViewCell.nibName, bundle: nil)
        self.tableView.register(detailCellNib, forCellReuseIdentifier: DisclosureIndicatorButtonTableViewCell.reuseID)
        
        let recentCellNib = UINib(nibName: RecentEntryTableViewCell.nibName, bundle: nil)
        self.tableView.register(recentCellNib, forCellReuseIdentifier: RecentEntryTableViewCell.reuseID)
    }
    
    func refreshNavigation() {
        self.navigationItem.leftBarButtonItem = self.moving ? self.cancelButton : nil
        self.navigationItem.rightBarButtonItems = self.moving ? [] : nil
        self.navigationItem.title = self.moving ? NSLocalizedString("Select Target", comment: "") : NSLocalizedString("Time", comment: "")
    }
        
    // MARK: - Data Methods and Actions
    
    func loadData(refresh: Bool = false) {
        var categoriesDone = false
        var entriesDone = false
        
        let completion: (Error?) -> Void = { error in
            DispatchQueue.main.async {
                if categoriesDone && entriesDone {
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                }
                
                // TODO: Show errors as-needed
                self.tableView.reloadData()
            }
        }
        
        let networkMode: Store.NetworkMode = refresh ? .refreshAll : .asNeeded
        Time.shared.store.getCategories(networkMode) { (categories, error) in categoriesDone = true; completion(error) }
        Time.shared.store.getEntries(networkMode) { (entries, error) in entriesDone = true; completion(error) }
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
    
    func calculateRecents() {
        let maxDays = 7 // Max time
        let maxResults = 5 // Max recent entries
        
        let entries = Time.shared.store.entries
        
        let cutoff = Date().addingTimeInterval(Double(-maxDays * 24 * 60 * 60))
        
        let filteredEntries = entries.filter { (entry) -> Bool in
            return entry.startedAt > cutoff
        }
        let orderedEntries = filteredEntries.sorted(by: { $0.startedAt > $1.startedAt })
        let orderedCategoryIDs = orderedEntries.map({ $0.categoryID })
        var reducedOrderedIDs: [Int] = []
        orderedCategoryIDs.forEach { (id) in
            guard !reducedOrderedIDs.contains(id) else { return }
            reducedOrderedIDs.append(id)
        }
        
        let recentCategoryIDs = reducedOrderedIDs.prefix(maxResults)
                
        let recentCategories = recentCategoryIDs.compactMap { (id) -> CategoryTree? in
            guard
                let category = Time.shared.store.categories.first(where: { $0.id == id }),
                let root = Time.shared.store.categoryTrees[category.accountID],
                let categoryTree = root.findItem(withID: category.id)
            else { return nil }
            
            return categoryTree
        }

        self.recentCategories = recentCategories
        if self.recentCategories.count == 0 {
            self.controls = self.controls.filter({ $0 != .recents })
        } else {
            if !self.controls.contains(.recents) {
                self.controls.insert(.recents, at: 0)
            }
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
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
    
    @IBAction func importPressed(_ sender: Any) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "importListView") as? ImportListViewController else { return }
        let importNavVC = UINavigationController(rootViewController: vc)
        self.present(importNavVC, animated: true, completion: nil)
    }
    
    // MARK: - Table View
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.loadData(refresh: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let controlsSections = self.controls.count
        let accountSections = Time.shared.store.accountIDs.count
        let moreControlsSection = self.moreControls.count > 0 ? 1 : 0
        
        return controlsSections + accountSections + moreControlsSection
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section >= self.controls.count else {
            let controlType = self.controls[section]
            return controlType.title
        }
        
        // No title for 'more' section or accounts. Root is title
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section >= self.controls.count else {
            let controlType = self.controls[section]
            guard controlType != .recents else {
                return self.recentCategories.count
            }
            guard let rows = self.controlRows[controlType] else { return 0 }
            return rows
        }
        if section == self.controls.count + Time.shared.store.accountIDs.count {
            let header = 1
            let controls = self.expandMoreControls ? self.moreControls.count : 0
            return header + controls
        }

        guard let tree = self.getTree(for: section) else { return 0 }
        return tree.numberOfDisplayRows(overrideExpanded: self.moving, includeRoot: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section >= self.controls.count else {
            let controlType = self.controls[indexPath.section]
            
            switch controlType {
                case .recents:
                    let categoryTree = self.recentCategories[indexPath.row]
                    let cell = tableView.dequeueReusableCell(withIdentifier: RecentEntryTableViewCell.reuseID, for: indexPath) as! RecentEntryTableViewCell
                    cell.configure(for: categoryTree)
//                    cell.backgroundColor = .secondarySystemGroupedBackground
                    return cell
                
                case .entries:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DisclosureIndicatorButtonTableViewCell.reuseID, for: indexPath) as! DisclosureIndicatorButtonTableViewCell
                    cell.buttonText = NSLocalizedString("Show All Entries", comment: "")
//                    cell.backgroundColor = .secondarySystemGroupedBackground
                    return cell
                
                default:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
                    cell.textLabel?.text = ""
                    cell.detailTextLabel?.text = controlType.rawValue
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    return cell
            }
        }
        
        if indexPath.section == self.controls.count + Time.shared.store.accountIDs.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
            if indexPath.row == 0 {
                cell.textLabel?.text = ""
                cell.detailTextLabel?.text = "More"
            } else {
                let controlType = self.moreControls[indexPath.row - 1]
                cell.textLabel?.text = ""
                cell.detailTextLabel?.text = controlType.rawValue
            }
            
            cell.backgroundColor = .secondarySystemGroupedBackground
            return cell
        }
        
        guard let categoryTree = self.getTree(for: indexPath) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
            cell.textLabel?.text = "ERROR"
            cell.detailTextLabel?.text = "ERROR"
            return cell
        }
        let category = categoryTree.node
        
        var backgroundColor: UIColor = .secondarySystemGroupedBackground
        if self.moving {
            let isValidTarget = Time.shared.store.canMove(self.movingCategory!, to: category)
            let isSelf = self.movingCategory?.id == category.id
            backgroundColor = isSelf ? .systemYellow : (isValidTarget ? .secondarySystemGroupedBackground : .systemGroupedBackground)
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
        guard indexPath.section >= self.controls.count else { return nil }
        if indexPath.section == self.controls.count + Time.shared.store.accountIDs.count {
            return nil
        }
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
        let isControl = indexPath.section < self.controls.count
        let isRecent = isControl && self.controls[indexPath.section] == .recents
        guard isRecent || !isControl else { return nil }

        if indexPath.section == self.controls.count + Time.shared.store.accountIDs.count {
            return nil
        }
        
        guard let categoryTree = (
            isRecent
                ? self.recentCategories[indexPath.row]
                : self.getTree(for: indexPath)
        ) else { return nil }
        
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
        guard indexPath.section >= self.controls.count else {
            let control = self.controls[indexPath.section]
            switch control {
            case .entries:
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let entriesVC = storyboard.instantiateViewController(withIdentifier: "entriesView")
                self.navigationController?.pushViewController(entriesVC, animated: true)
            default:
                break
            }
            return
        }
        
        if indexPath.section == self.controls.count + Time.shared.store.accountIDs.count {
            guard self.moving == false else { return }
            
            if indexPath.row == 0 {
                self.expandMoreControls = !self.expandMoreControls
                self.tableView.reloadSections([indexPath.section], with: .automatic)
                return
            }
            
            let control = self.moreControls[indexPath.row - 1]
            switch control {
            case .addAccount:
                self.addPressed(self)
            case .importRecords:
                self.importPressed(self)
            case .signOut:
                self.signOutPressed(self)
            default:
                break
            }
            return
        }
        
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
    
    @objc func safeReload() {
        if Thread.isMainThread {
            self.tableView.reloadData()
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView <-> Data store support methods
    
    func getTree(for section: Int) -> CategoryTree? {
        guard section >= self.controls.count else { return nil }

        let correctedSection = section - self.controls.count
        guard correctedSection < Time.shared.store.accountIDs.count else { return nil }
        let accountID = Time.shared.store.accountIDs[correctedSection]
        guard let tree = Time.shared.store.categoryTrees[accountID] else { return nil }
        
        return tree
    }
    
    func getTree(for indexPath: IndexPath) -> CategoryTree? {
        guard let tree = self.getTree(for: indexPath.section) else { return nil }
        return tree.getChild(withOffset: indexPath.row, overrideExpanded: self.moving)
    }
}
