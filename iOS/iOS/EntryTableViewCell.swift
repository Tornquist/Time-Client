//
//  EntryTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 6/15/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

protocol EntryTableViewCellDelegate: class {
    func stop(entryID: Int, sender: EntryTableViewCell)
}

class EntryTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // Other
    static let nibName: String = "EntryTableViewCell"
    static let reuseID: String = "entryTableViewCell"
            
    var entryID: Int? = nil
    weak var delegate: EntryTableViewCellDelegate? = nil
    
    // Shared between all instances
    static var dateFormatters: [String:DateFormatter] = [:]
    
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
        
        self.topLabel.font = UIFont.systemFont(ofSize: 17.0)
        self.bottomLabel.font = UIFont.systemFont(ofSize: 12.0)
        
        self.actionButton.setTitle(nil, for: .normal)
        let imageConfiguration = UIImage.SymbolConfiguration(scale: .large)
        self.actionButton.setImage(UIImage(systemName: "stop.circle", withConfiguration: imageConfiguration), for: .normal)
        self.actionButton.tintColor = Colors.button
    }
    
    public func configure(for entry: Entry) {
        guard
            let category = Time.shared.store.categories.first(where: { $0.id == entry.categoryID }),
            let accountTree = Time.shared.store.categoryTrees[category.accountID],
            let categoryTree = accountTree.findItem(withID: category.id)
        else {
            let errorText = NSLocalizedString("Error", comment: "")
            self.topLabel.text = errorText
            self.bottomLabel.text = errorText
            self.actionButton.isHidden = true
            self.entryID = nil
            return
        }
        
        self.entryID = entry.id
        
        var displayNameParts = [categoryTree.node.name]
        var position = categoryTree.parent
        while position != nil {
            // Make sure exists and is not root
            if position != nil && position?.parent != nil {
                displayNameParts.append(position!.node.name)
            }
            position = position?.parent
        }
        
        let displayName = displayNameParts.reversed().joined(separator: " > ")
        let timeText = self.getTimeString(for: entry)
        
        self.topLabel.text = displayName
        self.bottomLabel.text = timeText
        
        let isOpen = entry.type == .range && entry.endedAt == nil
        self.actionButton.isHidden = !isOpen
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        guard let entryID = self.entryID else { return }
        
        self.delegate?.stop(entryID: entryID, sender: self)
    }
    
    // MARK: - Time Formatting
    
    func getTimeString(for entry: Entry) -> String {
        let startedAtString = self.format(time: entry.startedAt, with: entry.startedAtTimezone)
        let endedAtString = entry.endedAt != nil ? self.format(time: entry.endedAt!, with: entry.endedAtTimezone) : nil
        
        var timeText = ""
        if entry.type == .event {
            timeText = "@ \(startedAtString)"
        } else if entry.endedAt == nil {
            timeText = "\(startedAtString) - \(NSLocalizedString("Present", comment: ""))"
        } else {
            // Depends on stable string formatting
            let sameDay = endedAtString != nil && (startedAtString.prefix(8) == endedAtString!.prefix(8))
            if !sameDay {
                timeText = "\(startedAtString) - \(endedAtString!)"
            } else {
                let endedAtWithoutDate = endedAtString!.dropFirst(9)
                timeText = "\(startedAtString) - \(endedAtWithoutDate)"
            }
        }
        return timeText
    }
    
    func format(time: Date, with timezoneIdentifier: String?) -> String {
        let defaultTimezone = TimeZone.autoupdatingCurrent
        let safeTimezone = timezoneIdentifier ?? defaultTimezone.identifier
        if (EntryTableViewCell.dateFormatters[safeTimezone] == nil) {
            let timezone = TimeZone(identifier: safeTimezone) ?? defaultTimezone
            if (EntryTableViewCell.dateFormatters[timezone.identifier] == nil) {
                let newFormatter = DateFormatter.init()
                newFormatter.dateFormat = "MM/dd/YY hh:mm a zzz"
                newFormatter.timeZone = timezone
                EntryTableViewCell.dateFormatters[safeTimezone] = newFormatter
            }
        }
        
        return EntryTableViewCell.dateFormatters[safeTimezone]!.string(from: time)
    }
}

