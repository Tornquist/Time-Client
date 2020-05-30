//
//  MetricTotalSplitView.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/30/20.
//  Copyright © 2020 nathantornquist. All rights reserved.
//

import UIKit

class MetricTotalSplitView: UIView {

    static let nibName: String = "MetricTotalSplitView"
    
    // Views
    private var view: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    // MARK: - Init
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureTheme()
        self.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.configureNib()
        self.configureTheme()
        self.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configureNib()
    }
    
    private func configureNib() {
        self.view = loadViewFromNib()
        self.view.frame = bounds
        self.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        self.addSubview(self.view)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for:type(of: self))
        let nib = UINib(nibName: MetricTotalSplitView.nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    // MARK: - View Configuration
    
    private func configureTheme() {
        self.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.clear
        
        self.nameLabel.font = UIFont.systemFont(ofSize: 12.0)
        self.valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .regular)
    }
    
    public func configure(withName name: String, andValue value: String) {
        self.nameLabel.text = name
        self.valueLabel.text = value
    }
}
