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
    @IBOutlet weak var splitStackView: UIStackView!
        
    // Other
    static let nibName: String = "MetricTotalTableViewCell"
    static let reuseID: String = "metricTotalTableViewCell"
    
    var storedSplits: [String: MetricTotalSplitView] = [:]
    
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
    }
    
    public func configure(forRange range: String, withTime time: String, andSplits splits: [String:String]?) {
        self.timeLabel.text = time
        self.timeRangeLabel.text = range
        
        guard splits != nil else {
            self.splitStackView.isHidden = true
            self.storedSplits.keys.forEach { (splitName) in
                self.removeSplit(withName: splitName)
            }
            return
        }
        
        let activeSplits = Set(self.storedSplits.keys)
        let expectedSplits = Set(splits!.keys)

        let extraSplits = activeSplits.subtracting(expectedSplits)
        let neededSplits = expectedSplits.subtracting(activeSplits)
        let updatingSplits = expectedSplits.subtracting(neededSplits)
        
        extraSplits.forEach({ (splitName) in self.removeSplit(withName: splitName) })
        neededSplits.forEach({ self.insertSplit(withName: $0, andValue: splits![$0] ?? "" )})
        updatingSplits.forEach({ self.updateSplit(withName: $0, andValue: splits![$0] ?? "" )})
    }
    
    private func updateSplit(withName name: String, andValue value: String) {
        guard let splitView = self.storedSplits[name] else { return }
        splitView.configure(withName: name, andValue: value)
    }
    
    private func insertSplit(withName name: String, andValue value: String) {
        let newSplitView = MetricTotalSplitView(frame: .zero)
        newSplitView.translatesAutoresizingMaskIntoConstraints = false
        newSplitView.configure(withName: name, andValue: value)
        
        let expectedKeys: [String] = (Array(self.storedSplits.keys) + [name]).sorted()
        let expectedIndex: Int = expectedKeys.firstIndex(of: name)!
        
        self.splitStackView.insertArrangedSubview(newSplitView, at: expectedIndex)
        self.storedSplits[name] = newSplitView
    }
    
    private func removeSplit(withName name: String) {
        guard let splitView = self.storedSplits[name] else { return }
        
        self.splitStackView.removeArrangedSubview(splitView)
        splitView.removeFromSuperview()
        self.storedSplits.removeValue(forKey: name)
    }
}
