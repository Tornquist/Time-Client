//
//  CategoryTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/6/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class CategoryTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak var expandedIconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var leadingContraint: NSLayoutConstraint!
    
    // Other
    static let nibName: String = "CategoryTableViewCell"
    static let reuseID: String = "categoryTableViewCell"
    
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
        
        self.expandedIconView.contentMode = .center
        self.expandedIconView.tintColor = Colors.button
        
        self.nameLabel.text = nil
        self.expandedIconView.image = nil
    }
    
    public func configure(with name: String, depth: Int, isExpanded expanded: Bool, hasChildren children: Bool, isActive active: Bool) {
        self.nameLabel.text = name
        
        let imageConfiguration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 12.0, weight: .semibold))
        let imageName = !children ? nil : (expanded ? "chevron.down" : "chevron.right")
        let image = imageName == nil ? nil : UIImage(systemName: imageName!, withConfiguration: imageConfiguration)
        self.expandedIconView.image = image
        
        let cellOffset: CGFloat = CGFloat(depth) * (16 /* icon width */ + 12 /* icon to label space */) + 12 /* base offset */
        self.leadingContraint.constant = cellOffset
        
        self.nameLabel.textColor = active ? Colors.active : UIColor.label
    }
}
