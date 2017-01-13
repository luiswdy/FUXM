//
//  FUBatteryInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/13/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

enum FUBatteryStatus: UInt8 {
    case
    normal = 0, low, charging, chargingFull, chargeOff
}

class FUBatteryInfo: NSObject {
    let level: UInt8
    let lastChargeDate: Date
    let chargesCount: UInt16
    let status: FUBatteryStatus
    
    struct Consts {
        static let levelRange: Range<Data.Index> = 0..<1
        static let lastChargeDateRange: Range<Data.Index> = 1..<7
        static let chargesCountRange: Range<Data.Index> = 7..<9
        static let statusRange: Range<Data.Index> = 9..<10
        static let timeZoneSecondsFromGMT = 0
        static let yearBase = 2000
        static let monthBase = 1
        static let monthOffset = 1
        static let dayOffset = 2
        static let hourOffset = 3
        static let minuteOffset = 4
        static let secondOffset = 5
    }
    
    override var debugDescription: String {
        return "level: \(level), "
            + "lastChargeDate: \(lastChargeDate) "
            + "chargesCount: \(chargesCount), "
            + "status: \(status)"
    }
    
    init?(data: Data?) {
        if let data = data {
            self.level = data.subdata(in: Consts.levelRange).withUnsafeBytes( { return $0.pointee } )
            self.lastChargeDate = data.subdata(in: Consts.lastChargeDateRange).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> Date in
                let calendar = Calendar(identifier: .gregorian)
                let timeZone = TimeZone(secondsFromGMT: Consts.timeZoneSecondsFromGMT)
                var dateComponents = DateComponents(calendar: calendar, timeZone: timeZone)
                dateComponents.year = Consts.yearBase + Int(pointer.pointee)
                dateComponents.month = Consts.monthBase + Int(pointer.advanced(by: Consts.monthBase).pointee)
                dateComponents.day = Int(pointer.advanced(by: Consts.dayOffset).pointee)
                dateComponents.hour = Int(pointer.advanced(by: Consts.hourOffset).pointee)
                dateComponents.minute = Int(pointer.advanced(by: Consts.minuteOffset).pointee)
                dateComponents.second = Int(pointer.advanced(by: Consts.secondOffset).pointee)
                return dateComponents.date!
            })
            self.chargesCount = data.subdata(in: Consts.chargesCountRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
            if let status = FUBatteryStatus(rawValue: data.subdata(in: Consts.statusRange).withUnsafeBytes { return $0.pointee }) {
                self.status = status
            } else {
                self.status =  .normal  // default
            }
            super.init()
        } else {
            return nil
        }
    }
    
}
