//
//  NewImportViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 12/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit

class NewImportViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTheme()
    }
    
    func configureTheme() {
        self.navigationItem.title = NSLocalizedString("New Import", comment: "")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed(_:)))
    }
    
    // MARK: - Events
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
