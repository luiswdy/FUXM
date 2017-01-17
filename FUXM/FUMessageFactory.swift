//
//  FUMessageFactory.swift
//  FUXM
//
//  Created by Luis Wu on 1/17/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import UIKit

class FUMessageFactory {
    static func simpleMessageView(title: String?, message: String, dismissButtonText: String = "Dismiss") -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissButtonText, style: .default, handler: nil))
        return alert
    }
    
}

