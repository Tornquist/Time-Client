//
//  RecentEntryTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 4/26/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class RecentEntryTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak var entryNameLabel: UILabel!
    @IBOutlet weak var entryParentsLabel: UILabel!
    
    // Other
    static let nibName: String = "RecentEntryTableViewCell"
    static let reuseID: String = "recentEntryTableViewCell"
    
    @IBOutlet weak var actionButton: UIButton!
    
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
        
        self.entryNameLabel.font = UIFont.systemFont(ofSize: 17.0)
        self.entryParentsLabel.font = UIFont.systemFont(ofSize: 12.0)
        
        self.actionButton.setTitle(nil, for: .normal)
        let imageConfiguration = UIImage.SymbolConfiguration(scale: .large)
        self.actionButton.setImage(UIImage(systemName: "play.circle", withConfiguration: imageConfiguration), for: .normal)
    }
    
    public func configure(for tree: CategoryTree) {
        let entryName = tree.node.name
        
        var parentNameParts: [String] = []
        var position = tree.parent
        while position != nil {
            // Make sure exists and is not root
            if position != nil && position?.parent != nil {
                parentNameParts.append(position!.node.name)
            }
            position = position?.parent
        }
                
        let possibleParentName = parentNameParts.reversed().joined(separator: " > ")
        let parentName = possibleParentName.count > 0 ? possibleParentName : NSLocalizedString("Account \(tree.node.accountID)", comment: "")
        
        self.entryNameLabel.text = entryName
        self.entryParentsLabel.text = parentName
        
        self.actionButton.isHidden = true // TODO: Implement action button (requires system triggers for top-level updates)
    }
}
