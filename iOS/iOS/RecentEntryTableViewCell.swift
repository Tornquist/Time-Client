//
//  RecentEntryTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 4/26/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

protocol RecentEntryTableViewCellDelegate: class {
    func toggle(categoryID: Int)
    func record(categoryID: Int)
}

class RecentEntryTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak var entryNameLabel: UILabel!
    @IBOutlet weak var entryParentsLabel: UILabel!
    
    // Other
    static let nibName: String = "RecentEntryTableViewCell"
    static let reuseID: String = "recentEntryTableViewCell"
    
    @IBOutlet weak var actionButton: UIButton!
    
    private var configuredForCategoryID: Int? = nil
    private var configuredAsRange: Bool = true
    
    weak var delegate: RecentEntryTableViewCellDelegate? = nil
    
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
    
    public func configure(for tree: CategoryTree, asRange: Bool) {
        // Record Configuration
        self.configuredAsRange = asRange
        self.configuredForCategoryID = tree.node.id
        
        // Configure Cell
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
        
        let category = tree.node
        if asRange {
            let isRangeOpen = Time.shared.store.isRangeOpen(for: category) == true
            let imageName = isRangeOpen ? "pause.circle" : "play.circle"
            self.actionButton.setImage(
                UIImage(
                    systemName: imageName,
                    withConfiguration:
                    UIImage.SymbolConfiguration(scale: .large)
                ),
                for: .normal
            )
        } else {
            self.actionButton.setImage(
                UIImage(
                    systemName: "smallcircle.fill.circle",
                    withConfiguration:
                    UIImage.SymbolConfiguration(scale: .large)
                ),
                for: .normal
            )
        }
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        guard let categoryID = self.configuredForCategoryID else { return }
        
        if self.configuredAsRange {
            self.delegate?.toggle(categoryID: categoryID)
        } else {
            self.delegate?.record(categoryID: categoryID)
        }
    }
}
