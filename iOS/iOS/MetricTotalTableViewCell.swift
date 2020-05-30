//
//  MetricTotalTableViewCell.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/30/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit

class MetricTotalTableViewCell: UITableViewCell {
    
    // Views
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeRangeLabel: UILabel!
    @IBOutlet weak var splitNameLabel: UILabel!
    @IBOutlet weak var splitValueLabel: UILabel!
        
    // Other
    static let nibName: String = "MetricTotalTableViewCell"
    static let reuseID: String = "metricTotalTableViewCell"
    
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

        self.timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 34.0, weight: .regular)
        self.timeRangeLabel.font = UIFont.systemFont(ofSize: 12.0)
        
        self.splitNameLabel.font = UIFont.systemFont(ofSize: 12.0)
        self.splitValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .regular)
    }
    
    public func configure(forRange range: String, withTime time: String, andSplits splits: [String:String]?) {
        self.timeLabel.text = time
        self.timeRangeLabel.text = range
        
        guard splits != nil else {
            self.splitNameLabel.text = nil
            self.splitNameLabel.isHidden = true
            self.splitValueLabel.text = nil
            self.splitValueLabel.isHidden = true
            return
        }
        
        self.splitNameLabel.isHidden = false
        self.splitValueLabel.isHidden = false
                
        let names = Array(splits!.keys).sorted()
        let values = names.map({ splits![$0] ?? "" })
        
        let currentWidth = self.splitNameLabel.frame.width
        let displayNames = names.map { (name) -> String in
            let giantFrame = CGSize(width: 1000, height: 1000)
            
            let size = (name as NSString?)?.boundingRect(
                with: giantFrame,
                options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin],
                attributes: [NSAttributedString.Key.font: self.splitValueLabel.font ?? UIFont.systemFont(ofSize: 12.0)],
                context: nil
            ).size
            
            guard size?.width ?? giantFrame.width > currentWidth else {
                // Exit if no truncation needed
                return name
            }
            
            var searching = true
            var step = 0
            var truncatedName = name
            let addition = "..."
            
            while searching {
                _ = truncatedName.removeLast()
                let testSize = ((truncatedName + addition) as NSString?)?.boundingRect(
                    with: giantFrame,
                    options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin],
                    attributes: [NSAttributedString.Key.font: self.splitValueLabel.font ?? UIFont.systemFont(ofSize: 12.0)],
                    context: nil
                ).size
                
                if testSize?.width ?? giantFrame.width < currentWidth || step > 50 {
                    searching = false
                }
                step = step + 1
            }
            return truncatedName + addition
        }
        
        let namesText = displayNames.joined(separator: "\n")
        let valuesText = values.joined(separator: "\n")

        self.splitNameLabel.text = namesText
        self.splitValueLabel.text = valuesText
    }
}
