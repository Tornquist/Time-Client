//
//  ViewController.swift
//  Time-macOS
//
//  Created by Nathan Tornquist on 12/9/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import Cocoa
import Time

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        
        Time.shared.authenticate(email: "test@test.com", password: "defaultPassword")
    }
}

