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

        self.timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)
        self.timeRangeLabel.font = UIFont.systemFont(ofSize: 12.0)
    }
    
    public func configure(forRange range: String, withTime time: String) {
        self.timeLabel.text = time
        self.timeRangeLabel.text = range
    }
}
