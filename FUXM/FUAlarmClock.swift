//
//  FUAlarmClock.swift
//  FUXM
//
//  Created by Luis Wu on 1/15/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

struct FURepetition: OptionSet {
    var rawValue: UInt8
    
    static let once = 0
    static let monday = 1
    static let tuesday = 2
    static let wednesday = 4
    static let thursday = 8
    static let friday = 16
    static let saturday = 32
    static let sunday = 64
    static let weekDays = [ monday, tuesday, wednesday, thursday, friday ]
    static let weekend = [ saturday, sunday ]
    static let everyDay = [ weekDays, weekend]
}

class FUAlarmClock: NSObject {
    var index: UInt8
    var enable: Bool
    var dateTime: FUDateTime
    var enableSmartWakeUp: Bool
    var repetition: FURepetition
    
    struct Consts {
        static let indexRange: Range<Data.Index> = 0..<1
        static let enableRange: Range<Data.Index> = 1..<2
        static let dateTimeRange: Range<Data.Index> = 2..<8
        static let enableSmartWakeUpRange: Range<Data.Index> = 8..<9
        static let repetitionRange: Range<Data.Index> = 9..<10
        static let alarmEnable: UInt8 = 1
        static let alarmDisable: UInt8 = 0
        static let smartWakeUpEnable: UInt8 = 30
        static let smartWakeUpDisable:UInt8  = 0
    }
    
    override var debugDescription: String {
        return "index: \(index), enable: \(enable), dateTime: \(dateTime), enableSmartWakeUp: \(enableSmartWakeUp), repetition: \(repetition)"
    }
    
    init(index: UInt8, enable: Bool, dateTime: FUDateTime, enableSmartWakeUp: Bool, repetition: FURepetition) {
        self.index = index
        self.enable = enable
        self.dateTime = dateTime
        self.enableSmartWakeUp = enableSmartWakeUp
        self.repetition = repetition
    }
    
    init?(data: Data?) {
        guard let data = data else { return nil }
        index = data.subdata(in: Consts.indexRange).withUnsafeBytes { return $0.pointee }
        enable = data.subdata(in: Consts.enableRange).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> Bool in
            return pointer.pointee == 0 ? false : true
        })
        if let tmpDateTime = FUDateTime(data: data.subdata(in: Consts.dateTimeRange)) {
            dateTime = tmpDateTime
        } else {
            dateTime = FUDateTime()
        }
        enableSmartWakeUp = data.subdata(in: Consts.enableSmartWakeUpRange).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> Bool in
            return  pointer.pointee == 0 ? false : true
        })
        repetition = data.subdata(in: Consts.repetitionRange).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> FURepetition in
            return FURepetition(rawValue: pointer.pointee)
        })
    }
    
    func data() -> Data {
        var bytes: [UInt8] = []
        bytes.append(index)
        bytes.append(enable ? Consts.alarmEnable : Consts.alarmDisable)
        bytes.append(contentsOf: dateTime.data())
        bytes.append(enableSmartWakeUp ? Consts.smartWakeUpEnable : Consts.smartWakeUpDisable)
        bytes.append(repetition.rawValue)
        return Data(bytes: bytes)
    }
}
