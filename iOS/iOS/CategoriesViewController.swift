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
    var controls: [ControlSectionType] = [.metric, .recents, .entries]
    let controlRows: [ControlSectionType: Int] = [
        ControlSectionType.metric: 2, /* This Day, and This Week */
        ControlSectionType.entries: 1
    ]
    let moreControls: [ControlSectionType] = [
        .addAccount,
        .importRecords,
        .signOut
    ]
    var expandMoreControls: Bool = false
    
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
        
        let detailCellNib = UINib(nibName: DisclosureIndicatorButtonTableViewCell.nibName, bundle: nil)
        self.tableView.register(detailCellNib, forCellReuseIdentifier: DisclosureIndicatorButtonTableViewCell.reuseID)
        
        let recentCellNib = UINib(nibName: RecentEntryTableViewCell.nibName, bundle: nil)
        self.tableView.register(recentCellNib, forCellReuseIdentifier: RecentEntryTableViewCell.reuseID)
        
        let categoryCellNib = UINib(nibName: CategoryTableViewCell.nibName, bundle: nil)
        self.tableView.register(categoryCellNib, forCellReuseIdentifier: CategoryTableViewCell.reuseID)
        
        let metricTotalNib = UINib(nibName: MetricTotalTableViewCell.nibName, bundle: nil)
        self.tableView.register(metricTotalNib, forCellReuseIdentifier: MetricTotalTableViewCell.reuseID)
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
        
        switch sortMode {
            case .date:
                // Date sorting is default
                self.recentCategories = recentCategories
            case .name:
                self.recentCategories = recentCategories.sorted { $0.node.name < $1.node.name }
        }

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
        let controlsSections = self.controls.count
        let accountSections = Time.shared.store.accountIDs.count
        let moreControlsSection = self.moreControls.count > 0 ? 1 : 0
        
        return controlsSections + accountSections + moreControlsSection
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let isControl = section < self.controls.count
        let isFirstAccount = section == self.controls.count
        
        let shouldShowHeader = isControl || isFirstAccount
        guard shouldShowHeader else { return nil }
        
        let title = isControl ? self.controls[section].title : NSLocalizedString("Accounts", comment: "")
        
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
        let isControl = section < self.controls.count
        let isFirstAccount = section == self.controls.count
        
        let shouldShowHeader = isControl || isFirstAccount
        guard shouldShowHeader else { return 0 }
        
        return 37.0
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
        var backgroundColor: UIColor = .secondarySystemGroupedBackground
        
        guard indexPath.section >= self.controls.count else {
            let controlType = self.controls[indexPath.section]
            
            switch controlType {
                case .metric:
                    let isDay = indexPath.row == 0
                    let title = isDay ? NSLocalizedString("Today", comment: "") : NSLocalizedString("This Week", comment: "")
                    let showSeconds = false
                    // TODO: Add controls for seconds
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: MetricTotalTableViewCell.reuseID, for: indexPath) as! MetricTotalTableViewCell
                    cell.backgroundColor = backgroundColor
                                        
                    let hasData = isDay ? self.closedDayTimes != nil : self.closedWeekTimes != nil
                    guard hasData else {
                        let blank = showSeconds ? "XX:XX:XX" : "XX:XX"
                        cell.configure(forRange: title, withTime: blank, andSplits: nil)
                        return cell
                    }
                    
                    var totalByCategory: [Int: Double] = [:]

                    (self.openEntries ?? []).forEach { (entry) in
                        let duration = Date().timeIntervalSince(entry.startedAt)
                        totalByCategory[entry.categoryID] = (totalByCategory[entry.categoryID] ?? 0) + duration
                    }

                    (isDay ? self.closedDayTimes! : self.closedWeekTimes!).forEach { (record) in
                        totalByCategory[record.key] = (totalByCategory[record.key] ?? 0) + record.value
                    }
                                        
                    // Will group all into "unknown" if no category keys exist
                    var displayGroups: [String: Double] = [:]
                    totalByCategory.forEach { (record) in
                        let categoryID = record.key
                        let category = Time.shared.store.categories.first(where: { $0.id == categoryID })
                        let name = category?.name
                        
                        let unknownName = NSLocalizedString("Unknown", comment: "")
                        let safeName = name ?? unknownName
                        
                        displayGroups[safeName] = (displayGroups[safeName] ?? 0) + record.value
                    }
                    
                    let getTimeString = { (time: Int) -> String in
                        let seconds = (time % 60)
                        let minutes = (time / 60) % 60
                        let hours = (time / 3600)
                        
                        let timeString = showSeconds
                            ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                            : String(format: "%02d:%02d", hours, minutes)
                        return timeString
                    }
                    
                    var displaySplits: [String: String] = [:]
                    displayGroups.forEach { (record) in
                        let timeString = getTimeString(Int(record.value))
                        displaySplits[record.key] = timeString
                    }

                    let totalTime = totalByCategory.values.reduce(0, +)
                    let ti = Int(totalTime)
                    let timeString = getTimeString(ti)
                    
                    cell.configure(forRange: title, withTime: timeString, andSplits: displaySplits)
                    cell.layoutIfNeeded()
                    return cell
                case .recents:
                    let categoryTree = self.recentCategories[indexPath.row]
                    let categoryID = categoryTree.node.id
                    
                    let maxDays = 7 // TODO: Merge with recent calculations
                    let cutoff = Date().addingTimeInterval(Double(-maxDays * 24 * 60 * 60))
                    let matchingEntry = Time.shared.store.entries
                        .filter({ (entry) -> Bool in
                            return entry.categoryID == categoryID && entry.startedAt > cutoff
                        })
                        .sorted(by: { (a, b) -> Bool in
                            return a.startedAt > b.startedAt
                        }).first

                    let isRange = matchingEntry?.type == .range
                    let cell = tableView.dequeueReusableCell(withIdentifier: RecentEntryTableViewCell.reuseID, for: indexPath) as! RecentEntryTableViewCell
                    cell.configure(for: categoryTree, asRange: isRange)
                    cell.delegate = self
                    cell.backgroundColor = backgroundColor
                    return cell
                
                case .entries:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DisclosureIndicatorButtonTableViewCell.reuseID, for: indexPath) as! DisclosureIndicatorButtonTableViewCell
                    cell.buttonText = NSLocalizedString("Show All Entries", comment: "")
                    cell.backgroundColor = backgroundColor
                    return cell
                
                default:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
                    cell.textLabel?.text = ""
                    cell.detailTextLabel?.text = controlType.rawValue
                    cell.backgroundColor = backgroundColor
                    return cell
            }
        }
        
        if indexPath.section == self.controls.count + Time.shared.store.accountIDs.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reuseID, for: indexPath) as! CategoryTableViewCell
            if indexPath.row == 0 {
                cell.configure(with: NSLocalizedString("More", comment: ""), depth: 0, isExpanded: self.expandMoreControls, hasChildren: true)
            } else {
                let controlType = self.moreControls[indexPath.row - 1]
                let title = controlType.title ?? controlType.rawValue
                cell.configure(with: title, depth: 0, isExpanded: false, hasChildren: false)
            }
            
            cell.backgroundColor = .clear
            return cell
        }
        
        guard let categoryTree = self.getTree(for: indexPath) else {
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
        
        if category.parentID == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
            cell.textLabel?.text = "ACCOUNT \(category.accountID)"
            cell.backgroundColor = backgroundColor
            return cell
        }
            
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reuseID, for: indexPath) as! CategoryTableViewCell
        
        let depth = categoryTree.depth - 1 // Will not show account cell
        let isExpanded = categoryTree.expanded || self.moving
        let hasChildren = categoryTree.children.count > 0
        cell.configure(with: category.name, depth: depth, isExpanded: isExpanded, hasChildren: hasChildren)
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
            let section = self.controls.firstIndex(of: .metric),
            let numRows = self.controlRows[.metric]
            else { return }
        
        let indexPaths = (0..<numRows).map { IndexPath(row: $0, section: section) }
        self.tableView.reloadRows(at: indexPaths, with: .none)
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
