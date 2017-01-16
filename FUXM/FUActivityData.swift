//
//  FUActivityData.swift
//  FUXM
//
//  Created by Luis Wu on 1/16/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

class FUActivityData: NSObject {
    let intensity: UInt8
    let steps: UInt8
    let category: UInt8
    
    override var debugDescription: String {
        return "intensity: \(intensity), steps: \(steps), \(category): \(category)"
    }
    
    init(intensity: UInt8, steps: UInt8, category: UInt8) {
        self.intensity = intensity
        self.steps = steps
        self.category = category
        super.init()
    }
}
