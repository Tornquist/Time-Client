//
//  AccountTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 6/21/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class AccountTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak var nameLabel: UILabel!
    
    // Other
    static let nibName: String = "AccountTableViewCell"
    static let reuseID: String = "accountTableViewCell"
    
    // MARK: - init
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.configureTheme()
    }
    
    // MARK: - View Configuration
    
    private func configureTheme() {
        self.preservesSuperviewLayoutMargins = false
        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
        self.selectionStyle = .none
        
        self.nameLabel.font = UIFont.systemFont(ofSize: 15.0)
        self.nameLabel.text = nil
    }
    
    public func configure(with name: String) {
        self.nameLabel.text = name
    }
}
