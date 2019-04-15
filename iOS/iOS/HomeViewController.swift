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
    
    // MARK: - Data Methods
    
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
        return Time.shared.store.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let category = Time.shared.store.categories[indexPath.row]
        cell.textLabel?.text = "\(category.id)"
        cell.detailTextLabel?.text = category.name
        return cell
    }
}
