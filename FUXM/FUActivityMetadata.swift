//
//  FUActivityMetadata.swift
//  FUXM
//
//  Created by Luis Wu on 1/18/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

struct FUActivityMetadata: CustomDebugStringConvertible {
    static let metadataLength = 11      // the expected length, in byte, of metadata
    
    let dataType: FUActivityDataMode
    let timestamp: Date                 // expected to be gotten from FUDateTime
    let totalDataToRead: UInt16         // counter for all data held by the band. the unit is byte
    let bytesPerMinute: Int             // the amount of bytes used to record activities in a minute
    let dataUntilNextHeader: UInt16     // the amount of bytes held by this data block
    
    private struct Consts {
        static let activityMetadataLength = 11
        static let metadataTypeRange: Range<Data.Index> = 0..<1                     // byte 0 is the data type: 1 means that each minute is represented by a triplet of bytes
        static let metadatatimestampRange: Range<Data.Index> = 1..<7                // bytes 1 ~ 6 represents a timestamp
        static let metadataTotalDataToReadRange: Range<Data.Index> = 7..<9          // bytes 7 ~ 8 is the counter for all data held by the band
        static let metadataDataUntilNextHeaderRange: Range<Data.Index> = 9..<11     // bytes 9 ~ 10 counter of this data block
    }
    
    init?(data: Data, isSupportHeartRate: Bool) {
        if let rawDataType: Int = data.subdata(in: Consts.metadataTypeRange).withUnsafeBytes({ return $0.pointee }),
            let incomingDataType = FUActivityDataMode(rawValue: rawDataType),
            let incomingTimestamp = FUDateTime(data: data.subdata(in: Consts.metadatatimestampRange))?.toDate() {
            // there is a total of totalDataToRead that will come in chunks (3 or 4 bytes per minute if dataType == 1 (FUActiviyDataMode.dataLengthMinute)),
            // these chunks are usually 20 bytes long and grouped in blocks
            // after dataUntilNextHeader bytes we will get a new packet of 11 bytes that should be parsed
            // as we just did
            dataType = incomingDataType
            bytesPerMinute = Int(self.dataType == .dataLengthMinute ? FUActivityMetadata.getBytesPerMinuteOfActivityData(supportHeartRate: isSupportHeartRate) : 1)
            timestamp = incomingTimestamp
            totalDataToRead = data.subdata(in: Consts.metadataTotalDataToReadRange).withUnsafeBytes( { return ($0 as UnsafePointer<UInt16>).pointee }) * UInt16(bytesPerMinute)
            dataUntilNextHeader = data.subdata(in: Consts.metadataDataUntilNextHeaderRange).withUnsafeBytes( { return ($0 as UnsafePointer<UInt16>).pointee }) * UInt16(bytesPerMinute)
        } else {
            return nil
        }
    }
    
    init(dataType :FUActivityDataMode = .dataLengthMinute,
         timestamp: Date = Date.distantPast,
         totalDataToRead: UInt16 = 0,
         bytesPerMinute:Int = 0,
         dataUntilNextHeader: UInt16 = 0) {
        self.dataType = dataType
        self.timestamp = timestamp
        self.totalDataToRead = totalDataToRead
        self.bytesPerMinute =  bytesPerMinute
        self.dataUntilNextHeader = dataUntilNextHeader
    }
    
    private static func getBytesPerMinuteOfActivityData(supportHeartRate: Bool) -> Int {
        return supportHeartRate ? 4 : 3
    }
    
    var debugDescription: String {
        return "timestamp: \(timestamp), totalDataToRead: \(totalDataToRead), bytesPerMinute: \(bytesPerMinute), dataUntilNextHeader: \(dataUntilNextHeader)"
    }
}
