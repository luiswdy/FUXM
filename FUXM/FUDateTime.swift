//
//  FUDateTime.swift
//  FUXM
//
//  Created by Luis Wu on 1/13/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

    class FUDateTime: NSObject {
    // these properties store ORIGINAL values!
    var year: UInt
    var month: UInt
    var day: UInt
    var hour: UInt
    var minute: UInt
    var second: UInt
    
    struct Consts {
        static let timeZoneSecondsFromGMT = 0
        static let yearBase: UInt = 2000
        static let monthBase: UInt = 1
        static let yearRange: Range<Data.Index> = 0..<1
        static let monthRange: Range<Data.Index> = 1..<2
        static let dayRange: Range<Data.Index> = 2..<3
        static let hourRange: Range<Data.Index> = 3..<4
        static let minuteRange: Range<Data.Index> = 4..<5
        static let secondRange: Range<Data.Index>= 5..<6
        static let calendar = Calendar(identifier: .gregorian)
        static let timeZone = TimeZone(secondsFromGMT: timeZoneSecondsFromGMT)
        static let dataLength = 12
    }
    
    init?(data: Data?) {
        if let data = data, data.count == Consts.dataLength {
            year = Consts.yearBase + data.subdata(in: Consts.yearRange).withUnsafeBytes( {return $0.pointee} )
            month = Consts.monthBase + data.subdata(in: Consts.monthRange).withUnsafeBytes( {return $0.pointee} )
            day = data.subdata(in: Consts.dayRange).withUnsafeBytes( {return $0.pointee} )
            hour = data.subdata(in: Consts.hourRange).withUnsafeBytes( {return $0.pointee} )
            minute = data.subdata(in: Consts.minuteRange).withUnsafeBytes( {return $0.pointee} )
            second = data.subdata(in: Consts.secondRange).withUnsafeBytes( {return $0.pointee} )
            super.init()
        } else {
            return nil
        }
    }
    
    init(year: UInt = 0, month: UInt = 0, day: UInt = 0,
         hour: UInt = 0, minute: UInt = 0, second: UInt = 0) {
        self.year = year + Consts.yearBase
        self.month = month + Consts.monthBase
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        super.init()
    }
    
    init(date: Date) {
        var dateComponents = Consts.calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        self.year = UInt(dateComponents.year!)
        self.month = UInt(dateComponents.month!)
        self.day = UInt(dateComponents.day!)
        self.hour = UInt(dateComponents.hour!)
        self.minute = UInt(dateComponents.minute!)
        self.second = UInt(dateComponents.second!)
        super.init()
    }
    
    func data() -> Data {
        return Data(bytes: [ UInt8(self.year - Consts.yearBase), UInt8(self.month - Consts.monthBase), UInt8(day), UInt8(hour), UInt8(minute), UInt8(second)])
    }
    
    func toDate() -> Date? {
        var dateComponents = DateComponents(calendar: Consts.calendar, timeZone: Consts.timeZone)
        dateComponents.year = Int(year)
        dateComponents.month = Int(month)
        dateComponents.day = Int(day)
        dateComponents.hour = Int(hour)
        dateComponents.minute = Int(minute)
        dateComponents.second = Int(second)
        return dateComponents.date
    }
    
    override var debugDescription: String {
        return "year: \(year), month: \(month), day: \(day), hour: \(hour), minute: \(minute), second: \(second)"
    }
}
