//
//  ImportListViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 12/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class ImportListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewImportViewControllerDelegate {
    
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    func configureTheme() {
        self.navigationItem.title = NSLocalizedString("Imports", comment: "")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closePressed(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPressed(_:)))
        
        let topConstraint = NSLayoutConstraint(item: self.view!, attribute: .top, relatedBy: .equal, toItem: self.tableView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: self.tableView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
    }
    
    // MARK: - Data Methods and Actions
    
    func loadData(refresh: Bool = false) {
        let networkMode: Store.NetworkMode = refresh ? .refreshAll : .asNeeded
        Time.shared.store.getImportRequests(networkMode) { (requests, error) in
            DispatchQueue.main.async {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                
                self.refreshTableViewAndOptionallyRepeat()
            }
        }
    }
    
    // MARK: - Events
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPressed(_ sender: Any) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newImportView") as? NewImportViewController else { return }
        vc.delegate = self
        let importNavVC = UINavigationController(rootViewController: vc)
        self.present(importNavVC, animated: true, completion: nil)
    }
    
    // MARK: - Table View

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.loadData(refresh: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Time.shared.store.importRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "importCell", for: indexPath)
        let request = Time.shared.store.importRequests[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yy"
        let dateString = dateFormatter.string(from: request.createdAt)
        
        cell.textLabel?.text = dateString
        cell.detailTextLabel?.text = request.complete ? "Complete" : "Processing"
        return cell
    }
    
    func refreshTableViewAndOptionallyRepeat() {
        self.tableView.reloadData()
        
        let somethingPending = Time.shared.store.importRequests.map({ !$0.complete }).reduce(false, { $0 || $1 })
        if somethingPending {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                self.loadData(refresh: true)
            }
        }
    }
    
    // MARK: - NewImportViewControllerDelegate
    
    func didCreateNewImportRequest() {
        self.refreshTableViewAndOptionallyRepeat()
    }
}
