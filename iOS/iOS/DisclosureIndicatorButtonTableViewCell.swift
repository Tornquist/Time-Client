//
//  DisclosureIndicatorButtonTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 4/26/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit

class DisclosureIndicatorButtonTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak private var buttonLabel: UILabel!
    
    // Other
    static let reuseID: String = "disclosureIndicatorButtonTableViewCell"
    
    // Configuration
    
    var buttonText: String? {
        set {
            self.buttonLabel.text = newValue
        }
        get {
            return self.buttonLabel.text
        }
    }
    
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
        
        self.buttonLabel.font = UIFont.systemFont(ofSize: 15.0)
        self.buttonLabel.textColor = .systemBlue
    }
}
