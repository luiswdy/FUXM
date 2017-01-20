//
//  FUBatteryInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/13/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation.NSData

enum FUBatteryStatus: UInt8 {
    case
    normal = 0, low, charging, chargingFull, chargeOff
}

class FUBatteryInfo: CustomDebugStringConvertible, FUDataInitiable {
    let level: UInt8
    let lastChargeDate: FUDateTime
    let chargesCount: UInt16
    let status: FUBatteryStatus
    
    private struct Consts {
        static let levelRange: Range<Data.Index> = 0..<1
        static let lastChargeDateRange: Range<Data.Index> = 1..<7
        static let chargesCountRange: Range<Data.Index> = 7..<9
        static let statusRange: Range<Data.Index> = 9..<10
    }
    
    var debugDescription: String {
        return "level: \(level), "
            + "lastChargeDate: \(lastChargeDate) "
            + "chargesCount: \(chargesCount), "
            + "status: \(status)"
    }
    
    required init?(data: Data?) {
        if let data = data {
            self.level = data.subdata(in: Consts.levelRange).withUnsafeBytes( { return $0.pointee } )
            if let convertedDate = FUDateTime(data: data.subdata(in: Consts.lastChargeDateRange)) {
                self.lastChargeDate = convertedDate
            } else {
                return nil
            }
            self.chargesCount = data.subdata(in: Consts.chargesCountRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
            if let status = FUBatteryStatus(rawValue: data.subdata(in: Consts.statusRange).withUnsafeBytes { return $0.pointee }) {
                self.status = status
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
