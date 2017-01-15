//
//  FUSensorData.swift
//  FUXM
//
//  Created by Luis Wu on 1/15/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

class FUSensorData: NSObject {
    let counter: UInt16
    private(set) var step: UInt16
    private(set) var axis1: Int16
    private(set) var axis2: Int16
    private(set) var axis3: Int16
    
    override var debugDescription: String {
        return "counter: \(counter), step: \(step), axis1: \(axis1), axis2: \(axis2), axis3: \(axis3)"
    }
    
    struct Consts {
        
    }
    
    init?(data: Data?) {
        guard let data = data else { return nil }
        let rawBytes = [UInt8](data)
        // exquivalent to:
//        var rawBytes = [UInt8](repeatElement(0, count: data.count))
//        data.copyBytes(to: &rawBytes, count: data.count)
        
        if (rawBytes.count - 2) % 6 != 0 {
            debugPrint("Invalid sensor data length: \(rawBytes.count)")
            return nil
        }
//        counter = UInt16(rawBytes[1]  << UInt8(8)) & 0xff00
        counter = UInt16(rawBytes[0] & 0xff) | (UInt16(rawBytes[1] & 0xff) << 8)
        step = 0
        axis1 = 0
        axis2 = 0
        axis3 = 0
//        for index in stride(from: 0, to: rawBytes.count - 2 / 6, by: 1) {
//            step = UInt16(index * 6)
            axis1 = Int16(rawBytes[2] & 0xff) | (Int16(rawBytes[3] & 0x0f) << 8)
            if axis1 & Int16(0x800) != 0x0000 { axis1 -= Int16(0x1000) }
            axis2 = Int16(rawBytes[4] & 0xff) | (Int16(rawBytes[5] & 0x0f) << 8)
            if axis2 & Int16(0x800) != 0x0000 { axis2 -= Int16(0x1000) }
            axis3 = Int16(rawBytes[6] & 0xff) | (Int16(rawBytes[7] & 0x0f) << 8)
            if axis3 & Int16(0x800) != 0x0000 { axis3 -= Int16(0x1000) }
//            debugPrint("[loop] counter = \(counter), step: \(step), axis1 = \(axis1), axis2 = \(axis2), axis3 = \(axis3)")
//        }
        debugPrint("counter = \(counter), step: \(step), axis1 = \(axis1), axis2 = \(axis2), axis3 = \(axis3)")
        super.init()
    }
}
