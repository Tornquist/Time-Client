//
//  CategoriesViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 3/23/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class CategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentEntryTableViewCellDelegate {
    
    var cancelButton: UIBarButtonItem!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    var moving: Bool { return self.movingCategory != nil }
    var movingCategory: TimeSDK.Category? = nil
    
    enum ControlType: String {
        case metric
        case favorites
        case recents
        case entries
        case signOut
        case importRecords
        case addAccount
        
        var title: String? {
            switch self {
                case .metric:
                    return NSLocalizedString("Metrics", comment: "")
                case .recents:
                    return NSLocalizedString("Recents", comment: "")
                case .addAccount:
                    return NSLocalizedString("Add Account", comment: "")
                case .importRecords:
                    return NSLocalizedString("Import Records", comment: "")
                case .signOut:
                    return NSLocalizedString("Sign Out", comment: "")
                default:
                    return nil
            }
        }
    }
    
    var headerControls: [ControlType] = [.metric, .recents, .entries]
    var footerControls: [ControlType] = [.addAccount, .importRecords, .signOut]
    var expandFooterControls: Bool = false
    
    let controlRows: [ControlType: Int] = [
        ControlType.metric: 2, /* This Day, and This Week */
        ControlType.entries: 1
    ]
    
    var recentCategories: [CategoryTree] = []
    
    var closedWeekTimes: [Int: Double]? = nil
    var closedDayTimes: [Int: Double]? = nil
    var openEntries: [Entry]? = nil

    var secondUpdateTimer: Timer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureTheme()
        
        NotificationCenter.default.addObserver(self, selector: #selector(safeReload), name: .TimeBackgroundStoreUpdate, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryRecorded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryModified, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEntryNotification(_:)), name: .TimeEntryDeleted, object: nil)
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshNavigation()
        self.loadData()
        
        self.calculateRecents()
        self.calculateMetrics()
        
        self.secondUpdateTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        RunLoop.main.add(self.secondUpdateTimer!, forMode: .common)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.secondUpdateTimer?.invalidate()
        self.secondUpdateTimer = nil
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
        
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension

        // Account and Category Cells

        let accountCellNib = UINib(nibName: AccountTableViewCell.nibName, bundle: nil)
        self.tableView.register(accountCellNib, forCellReuseIdentifier: AccountTableViewCell.reuseID)
        
        let categoryCellNib = UINib(nibName: CategoryTableViewCell.nibName, bundle: nil)
        self.tableView.register(categoryCellNib, forCellReuseIdentifier: CategoryTableViewCell.reuseID)
        
        // Metrics and Specific Controls
        
        let metricTotalNib = UINib(nibName: MetricTotalTableViewCell.nibName, bundle: nil)
        self.tableView.register(metricTotalNib, forCellReuseIdentifier: MetricTotalTableViewCell.reuseID)
        
        let recentCellNib = UINib(nibName: RecentEntryTableViewCell.nibName, bundle: nil)
        self.tableView.register(recentCellNib, forCellReuseIdentifier: RecentEntryTableViewCell.reuseID)
        
        let detailCellNib = UINib(nibName: DisclosureIndicatorButtonTableViewCell.nibName, bundle: nil)
        self.tableView.register(detailCellNib, forCellReuseIdentifier: DisclosureIndicatorButtonTableViewCell.reuseID)
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
    
    // MARK: Account Creation
    
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
                        // Account sections currently sorted by ID -> Always added to end
                        let headerSections = self.headerControls.count
                        let accountSections = Time.shared.store.accountIDs.count
                        
                        let totalSections = headerSections + accountSections
                        let zeroOffset = totalSections - 1
                        
                        let indexSet = IndexSet(arrayLiteral: zeroOffset)
                        self.tableView.insertSections(indexSet, with: .automatic)
                    }, completion: nil)
                }
            }
        }
    }
    
    // MARK: Category Management
    
    func modify(tree: CategoryTree, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let category = tree.node
        
        self.showAlertFor(modifying: tree) { (action) in
            guard let action = action else {
                completion(false)
                return
            }

            switch action {
                case .addChild(let name):
                    self.handleAddChild(withName: name, atRootOf: tree, and: indexPath, completion: completion)
                case .move:
                    self.startMoving(category: category)
                    completion(true)
                case .rename(let newName):
                    self.handleRenaming(category: category, to: newName, at: indexPath, completion: completion)
                case .delete(let removeChildren):
                    self.handleDelete(tree: tree, at: indexPath, removeChildren: removeChildren, completion: completion)
            }
        }
    }
    
    func handleAddChild(withName name: String, atRootOf tree: CategoryTree, and indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let category = tree.node
        Time.shared.store.addCategory(withName: name, to: category) { (success, newCategory) in
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
                        }, completion: { _ in
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        })
                    } else {
                        self.tableView.reloadData()
                    }
                }
                completion(success)
            }
        }
    }
    
    func startMoving(category: TimeSDK.Category) {
        self.movingCategory = category
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshNavigation()
        }
    }
    
    func handleMove(of category: TimeSDK.Category, to newParent: TimeSDK.Category) {
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
    
    func handleRenaming(category: TimeSDK.Category, to newName: String, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        Time.shared.store.renameCategory(category, to: newName) { (success) in
            DispatchQueue.main.async {
                if (success) {
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                completion(success)
            }
        }
    }
    
    func handleDelete(tree: CategoryTree, at indexPath: IndexPath, removeChildren: Bool, completion: @escaping (Bool) -> Void) {
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
                    
                    // Refresh parent cell (for expand/collapse icon)
                    if let parentRow = parentRowStart {
                        let parentIndexPath = IndexPath(row: parentRow, section: indexPath.section)
                        self.tableView.reloadRows(at: [parentIndexPath], with: .none)
                    }
                    
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
    
    @objc func handleEntryNotification(_ notification:Notification) {
        self.calculateRecents()
        self.calculateMetrics()
    }
    
    func calculateRecents() {
        enum RecentSortMode {
            case date
            case name
        }
        
        let maxDays = 7 // Max time
        let maxResults = 5 // Max recent entries
        let sortMode: RecentSortMode = .name
        
        let cutoff = Date().addingTimeInterval(Double(-maxDays * 24 * 60 * 60))

        Time.shared.store.getEntries(after: cutoff) { (entries, error) in
            guard let entries = entries, error == nil else {
                self.headerControls = self.headerControls.filter({ $0 != .recents })
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                return
            }
            
            let orderedEntries = entries.sorted(by: { $0.startedAt > $1.startedAt })
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
            
            switch sortMode {
                case .date:
                    // Date sorting is default
                    self.recentCategories = recentCategories
                case .name:
                    self.recentCategories = recentCategories.sorted { $0.node.name < $1.node.name }
            }

            if self.recentCategories.count == 0 {
                self.headerControls = self.headerControls.filter({ $0 != .recents })
            } else {
                if !self.headerControls.contains(.recents) {
                    if let firstIndex = self.headerControls.firstIndex(of: .metric) {
                        // After Metrics
                        self.headerControls.insert(.recents, at: firstIndex + 1)
                    } else if let secondIndex = self.headerControls.firstIndex(of: .entries) {
                        // Before Entries
                        self.headerControls.insert(.recents, at: secondIndex)
                    } else {
                        // Fallback to first
                        self.headerControls.insert(.recents, at: 0)
                    }
                }
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func calculateMetrics() {
        let now = Date()
        let calendar = Calendar.current
        
        let dayComps = calendar.dateComponents([.day, .month, .year], from: now)
        let weekComps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)
        
        let startOfDay = calendar.date(from: dayComps)!
        let startOfWeek = calendar.date(from: weekComps)!
        
        let handleEntries = { (day: Bool) -> (([Entry]?, Error?) -> ()) in
            return { (entries: [Entry]?, error: Error?) in
                guard error == nil && entries != nil else {
                    if day {
                        self.closedDayTimes = nil
                    } else {
                        self.closedWeekTimes = nil
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    return
                }
                
                var closedRanges: [Entry] = []
                var openRanges: [Entry] = []
                
                entries!.forEach { (entry) in
                    guard entry.type == .range else { return }
                    
                    if entry.endedAt == nil {
                        openRanges.append(entry)
                    } else {
                        closedRanges.append(entry)
                    }
                }
                
                var closedTimes: [Int: Double] = [:]
                closedRanges.forEach { (entry) in
                    let duration = entry.endedAt!.timeIntervalSince(entry.startedAt)
                    closedTimes[entry.categoryID] = (closedTimes[entry.categoryID] ?? 0) + duration
                }
                
                if day {
                    self.closedDayTimes = closedTimes
                    self.openEntries = openRanges
                } else {
                    self.closedWeekTimes = closedTimes
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        Time.shared.store.getEntries(after: startOfDay, completion: handleEntries(true))
        Time.shared.store.getEntries(after: startOfWeek, completion: handleEntries(false))
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
    
    @objc func timerTick() {
        self.refreshMetrics()
    }
    
    // MARK: - Table View
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.loadData(refresh: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.getNumberOfSections()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = self.getTypeFor(section: section)
        guard let title = self.getTitleFor(type: sectionType) else { return nil }
        
        let view = UIView(frame: .zero)
        let label = UILabel(frame: .zero)
        label.text = title
        label.font = UIFont.systemFont(ofSize: 19.0, weight: .semibold)
        label.autoresizesSubviews = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: label.topAnchor, constant: -8),
            view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            label.leftAnchor.constraint(equalToSystemSpacingAfter: view.leftAnchor, multiplier: 0),
            view.rightAnchor.constraint(greaterThanOrEqualTo: label.rightAnchor, constant: 0)
        ])
        
        view.autoresizesSubviews = true
        
        view.backgroundColor = .clear
        label.backgroundColor = .clear
        
        return view
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = self.getTypeFor(section: section)
        guard let _ = self.getTitleFor(type: sectionType) else { return 0 }
        
        return 37.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = self.getTypeFor(section: section)
        return self.getRowsFor(type: sectionType)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultBackgroundColor: UIColor = .secondarySystemGroupedBackground
        
        let sectionType = self.getTypeFor(section: indexPath.section)
        switch sectionType {
            case .control(let controlId):
                let controlType = self.getHeaderSections()[controlId]
                switch controlType {
                    case .metric:
                        // Replace with metric enum/config
                        let isDay = indexPath.row == 0
                        // TODO: Add controls for seconds
                        let showSeconds = true
                    
                        let cell = tableView.dequeueReusableCell(withIdentifier: MetricTotalTableViewCell.reuseID, for: indexPath) as! MetricTotalTableViewCell
                        cell.backgroundColor = defaultBackgroundColor

                        let title = self.getMetricTitle(forDay: isDay)

                        guard let data = self.getFormattedMetricData(forDay: isDay, showSeconds: showSeconds) else {
                            let blank = showSeconds ? "XX:XX:XX" : "XX:XX"
                            cell.configure(forRange: title, withTime: blank, andSplits: nil)
                            return cell
                        }
                    
                        cell.configure(forRange: title, withTime: data.0, andSplits: data.1)
                        return cell

                    case .recents:
                        let (categoryTree, isRange) = self.getRecentData(forRow: indexPath.row)
                        let cell = tableView.dequeueReusableCell(withIdentifier: RecentEntryTableViewCell.reuseID, for: indexPath) as! RecentEntryTableViewCell
                        cell.configure(for: categoryTree, asRange: isRange)
                        cell.delegate = self
                        cell.backgroundColor = defaultBackgroundColor
                        return cell

                    case .entries:
                        let cell = tableView.dequeueReusableCell(withIdentifier: DisclosureIndicatorButtonTableViewCell.reuseID, for: indexPath) as! DisclosureIndicatorButtonTableViewCell
                        cell.buttonText = NSLocalizedString("Show All Entries", comment: "")
                        cell.backgroundColor = defaultBackgroundColor
                        return cell
                    
                    default:
                        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
                        cell.textLabel?.text = ""
                        cell.detailTextLabel?.text = controlType.rawValue
                        cell.backgroundColor = defaultBackgroundColor
                        return cell
                }
            case .account(let accountOffset):
                var backgroundColor: UIColor = .secondarySystemGroupedBackground
                guard
                    let parentTree = self.getTree(forAdjusted: accountOffset),
                    let categoryTree = parentTree.getChild(withOffset: indexPath.row, overrideExpanded: self.moving)
                    else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
                        cell.textLabel?.text = "ERROR"
                        cell.detailTextLabel?.text = "ERROR"
                        return cell
                }
                let category = categoryTree.node

                if self.moving {
                    let isValidTarget = Time.shared.store.canMove(self.movingCategory!, to: category)
                    let isSelf = self.movingCategory?.id == category.id
                    backgroundColor = isSelf ? .systemYellow : (isValidTarget ? .secondarySystemGroupedBackground : .systemGroupedBackground)
                }
                
                guard category.parentID != nil else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: AccountTableViewCell.reuseID, for: indexPath) as! AccountTableViewCell
                    cell.configure(with: "ACCOUNT \(category.accountID)")
                    cell.backgroundColor = backgroundColor
                    return cell
                }
                
                let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reuseID, for: indexPath) as! CategoryTableViewCell
                let depth = categoryTree.depth - 1 // Will not show account cell
                let isExpanded = categoryTree.expanded || self.moving
                let hasChildren = categoryTree.children.count > 0
                let isActive = self.openEntries?.contains(where: { $0.categoryID == categoryTree.node.id }) ?? false
                cell.configure(with: category.name, depth: depth, isExpanded: isExpanded, hasChildren: hasChildren, isActive: isActive)
                cell.backgroundColor = backgroundColor
                return cell
            
            case .moreControls:
                let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reuseID, for: indexPath) as! CategoryTableViewCell
                let isTitle = indexPath.row == 0
                let controlType = isTitle ? nil : self.footerControls[indexPath.row - 1]
                
                let title = isTitle ? NSLocalizedString("More", comment: "") : (controlType!.title ?? controlType!.rawValue)
                let expanded = isTitle ? self.expandFooterControls : false
                let hasChildren = isTitle
                
                cell.configure(with: title, depth: 0, isExpanded: expanded, hasChildren: hasChildren, isActive: false)
                cell.backgroundColor = .clear
                return cell
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let isControl = indexPath.section < self.headerControls.count
        let isRecent = isControl && self.headerControls[indexPath.section] == .recents
        guard isRecent || !isControl else { return nil }

        if indexPath.section == self.headerControls.count + Time.shared.store.accountIDs.count {
            return nil
        }
        
        guard let categoryTree = (
            isRecent
                ? self.recentCategories[indexPath.row]
                : self.getTree(for: indexPath)
        ) else { return nil }
        
        let category = categoryTree.node
        
        let isRoot = category.parentID == nil

        // Modify
        let modifyTitle = NSLocalizedString("Modify", comment: "")
        let modify = UIContextualAction(style: .normal, title: modifyTitle, handler: { (action, view, completion) in
            self.modify(tree: categoryTree, at: indexPath, completion: completion)
        })

        // Start/Stop
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
        
        // Record
        let recordTitle = NSLocalizedString("Record", comment: "")
        let record = UIContextualAction(style: .normal, title: recordTitle, handler: { (action, view, completion) in
            Time.shared.store.recordEvent(for: category) { (success) in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        })
        
        var actions: [UIContextualAction] = []
        
        if isOpen != nil && !isRoot {
            actions.append(startStop)
        }
        if !isRoot {
            actions.append(record)
        }
        if !isRecent {
            actions.append(modify)
        }
        
        guard actions.count > 0 else { return nil }
        
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section >= self.headerControls.count else {
            let control = self.headerControls[indexPath.section]
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
        
        if indexPath.section == self.headerControls.count + Time.shared.store.accountIDs.count {
            guard self.moving == false else { return }
            
            if indexPath.row == 0 {
                self.expandFooterControls = !self.expandFooterControls
                self.tableView.reloadSections([indexPath.section], with: .automatic)
                return
            }
            
            let control = self.footerControls[indexPath.row - 1]
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
            self.handleMove(of: self.movingCategory!, to: categoryTree.node)
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
            }, completion: { _ in
                // None prevents post-expand/collapse pulse on cell
                self.tableView.reloadRows(at: [indexPath], with: .none)
            })
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
    
    func refreshMetrics() {
        guard
            self.openEntries != nil &&
            self.openEntries!.count > 0,
            let section = self.headerControls.firstIndex(of: .metric),
            let numRows = self.controlRows[.metric]
            else { return }
        
        let indexPaths = (0..<numRows).map { IndexPath(row: $0, section: section) }
        self.tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    // MARK: - TableView <-> Data store support methods
    
    func getTree(for section: Int) -> CategoryTree? {
        guard section >= self.headerControls.count else { return nil }

        let correctedSection = section - self.headerControls.count
        guard correctedSection < Time.shared.store.accountIDs.count else { return nil }
        let accountID = Time.shared.store.accountIDs[correctedSection]
        guard let tree = Time.shared.store.categoryTrees[accountID] else { return nil }
        
        return tree
    }
    
    func getTree(forAdjusted section: Int) -> CategoryTree? {
        let accountID = Time.shared.store.accountIDs[section]
        guard let tree = Time.shared.store.categoryTrees[accountID] else { return nil }
        
        return tree
    }
    
    func getTree(for indexPath: IndexPath) -> CategoryTree? {
        guard let tree = self.getTree(for: indexPath.section) else { return nil }
        return tree.getChild(withOffset: indexPath.row, overrideExpanded: self.moving)
    }
    
    // MARK: - RecentEntryTableViewCellDelegate
    
    func toggle(categoryID: Int) {
        guard let category = Time.shared.store.categories.first(where: { $0.id == categoryID}) else { return }
        
        Time.shared.store.toggleRange(for: category, completion: nil)
    }
    
    func record(categoryID: Int) {
        guard let category = Time.shared.store.categories.first(where: { $0.id == categoryID}) else { return }
        
        Time.shared.store.recordEvent(for: category, completion: nil)
    }
}
