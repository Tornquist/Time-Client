//
//  ViewController.swift
//  Time-iOS
//
//  Created by Nathan Tornquist on 12/9/18.
//  Copyright © 2018 nathantornquist. All rights reserved.
//

import UIKit
import Time

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Time.shared.authenticate(username: "test@test.com", password: "defaultPassword")
    }
}
