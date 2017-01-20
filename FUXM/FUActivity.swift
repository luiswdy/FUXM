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
    
    struct Consts {
        static let intensityOffset = 1
        static let stepsOffset = 2
        static let heartRateOffset = 3
    }
    
    var debugDescription: String {
        return "\(timestamp), \(category), \(intensity), \(steps), \(heartRate)"
    }
    
    init?(timestamp: Date, isSupportHeartRate: Bool, data: Data?) {
        guard let data = data, data.count > 0 else { return nil }
        self.timestamp = timestamp
        if let category = FUActivityCategory(rawValue: data.withUnsafeBytes({ return $0.pointee })) {
            self.category = category
        } else {
            self.category = .activity   // fallback as we don't know what kind of activity it is
        }
        self.intensity = data.withUnsafeBytes({ return $0.advanced(by: Consts.intensityOffset).pointee })
        self.steps = data.withUnsafeBytes({ return $0.advanced(by: Consts.stepsOffset).pointee })
        self.heartRate = isSupportHeartRate ? data.withUnsafeBytes({ return $0.advanced(by: Consts.heartRateOffset).pointee }) : nil
    }
    
    init(timestamp: Date, category: FUActivityCategory, intensity: UInt8, steps: UInt8, heartRate: UInt8? = nil) {
        self.timestamp = timestamp
        self.category = category
        self.intensity = intensity
        self.steps = steps
        self.heartRate = heartRate
    }
    
}
