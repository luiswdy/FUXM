//
//  FUAlarmViewController.swift
//  FUXM
//
//  Created by Luis Wu on 1/21/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import UIKit

class FUAlarmViewController: UITableViewController, FUTabBarChildViewController {
    private var internalMibandController: MiBandController!
    
    // MARK - FUTabBarChildViewController
    var mibandController: MiBandController {
        get {
            return internalMibandController
        }
        set {
            internalMibandController = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
