//
//  FUActivity.swift
//  FUXM
//
//  Created by Luis Wu on 1/18/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

enum FUActivityCategory: Int8 {
    case deepSleep = 4
    case lightSleep = 5
    case activity = -1
    //case unknown = -1   // why repeated?
    case nonwear = 3
    case charging = 6
}

struct FUActivity: CustomDebugStringConvertible {
    let timestamp: Date     // calculated from metadata's timestamp + offset of the activity in the data chunk (note this is 3 or 4 bytes per minute)
    let category: FUActivityCategory
    let intensity: UInt8
    let steps: UInt8
    let heartRate: UInt8?
    
    var debugDescription: String {
        return "\(timestamp), \(category), \(intensity), \(steps), \(heartRate)"
    }
    
    init(timestamp: Date, category: FUActivityCategory, intensity: UInt8, steps: UInt8, heartRate: UInt8? = nil) {
        self.timestamp = timestamp
        self.category = category
        self.intensity = intensity
        self.steps = steps
        self.heartRate = heartRate
    }
    
}
