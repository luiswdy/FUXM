//
//  FUActivityMetadata.swift
//  FUXM
//
//  Created by Luis Wu on 1/18/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

struct FUActivityMetadata {
    var dataType: FUActivityDataMode
    var timestamp: Date // expected to be gotten from FUDateTime
    // counter for all data held by the band
    var totalDataToRead: UInt16
    let bytesPerMinute: UInt16
    // counter of this data block
    var dataUntilNextHeader: UInt16
    
    init(dataType :FUActivityDataMode = .dataLengthMinute,
         timestamp: Date = Date.distantPast,
         totalDataToRead: UInt16 = 0,
         bytesPerMinute: UInt16 = 0,
         dataUntilNextHeader: UInt16 = 0) {
        self.dataType = dataType
        self.timestamp = timestamp
        self.totalDataToRead = totalDataToRead
        self.bytesPerMinute =  bytesPerMinute
        self.dataUntilNextHeader = dataUntilNextHeader
    }
}
