//
//  FUActivityDataFragment.swift
//  FUXM
//
//  Created by Luis Wu on 1/16/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

class FUActivityDataFragment: NSObject {
    var type: UInt8
    var timestamp: FUDateTime
    var duration: UInt16
    var count: UInt16
    var activityDataList: [FUActivityData]
    
    override var debugDescription: String {
        return "type: \(type), timestamp: \(timestamp), duration: \(duration), count: \(count)"
    }
    
    init(type: UInt8 = 0, timestamp: FUDateTime = FUDateTime(), duration: UInt16 = 0, count: UInt16 = 0, activityDataList: [FUActivityData] = []) {
        self.type = type
        self.timestamp = timestamp
        self.duration = duration
        self.count = count
        self.activityDataList = activityDataList
        super.init()
    }
}
