//
//  ImportListViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 12/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit

class ImportListViewController: UIViewController {
    
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
    }
    
    // MARK: - Data Methods and Actions
    
    func loadData() {
        print("Loading Data")
    }
    
    // MARK: - Events
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPressed(_ sender: Any) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newImportView") as? NewImportViewController else { return }
        let importNavVC = UINavigationController(rootViewController: vc)
        self.present(importNavVC, animated: true, completion: nil)
    }
}
