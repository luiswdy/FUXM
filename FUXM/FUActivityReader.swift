//
//  FUActivityReader.swift
//  FUXM
//
//  Created by Luis Wu on 1/16/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation.NSData

enum FUActiviyDataMode: Int {
    case dataLengthByte = 0, dataLengthMinute = 1
}

class FUActivityReader: CustomDebugStringConvertible {
//    var metadata: FUActivityMetadata
//    var activitySegments: [FUActivitySegment]
    
    private struct Consts {
        static let activityMetadataLength = 11
        static let metadataTypeRange: Range<Data.Index> = 0..<1
        static let metadataTimestampRange: Range<Data.Index> = 1..<6
        static let metadataTotalDataToRead: Range<Data.Index> = 6..<8
        
    }
    
    var debugDescription: String {
        return "TODO"
    }
    
    init?(data: Data?, supportHeartRate: Bool = false) {    // TODO: default no here as I have only Mi band 1. It should come from FUDeviceInfo
        guard let data = data else { return nil }
//        metadata = FUActivityMetadata()
//        activitySegments = []
        
        if data.count == Consts.activityMetadataLength {
            /*metadata = */ handleMetadata(data: data, supportHeartRate: supportHeartRate)    // metadata
        } else {
            /*activitySegments = */handleSegment(data: data)    // activity segment
        }
        
        return nil  // TODO
    }
    
    private func handleMetadata(data: Data, supportHeartRate: Bool) /*-> FUActivityMetadata*/ {
        // byte 0 is the data type: 1 means that each minute is represented by a triplet of bytes
        
        let dataType: FUActiviyDataMode = FUActiviyDataMode(rawValue: data.subdata(in: Consts.metadataTypeRange).withUnsafeBytes( { return $0.pointee } )) != nil ? FUActiviyDataMode(rawValue: data.subdata(in: Consts.metadataTypeRange).withUnsafeBytes( { return $0.pointee } ))! : .dataLengthByte
        // bytes 1 ~ 6 represents a timestamp
        let timestamp = FUDateTime(data: data.subdata(in: Consts.metadataTimestampRange))
        // counter for all data held by the band
        var totalDataToRead = data.subdata(in: Consts.metadataTotalDataToRead).withUnsafeBytes( { return ($0 as UnsafePointer<UInt16>).pointee })
        let bytesPerMinute = UInt16(dataType == .dataLengthMinute ? getBytesPerMinuteOfActivityData(supportHeartRate: supportHeartRate) : 1)
        totalDataToRead = totalDataToRead * bytesPerMinute
        // counter of this data block
        var dataUntilNextHeader = data.subdata(in: Consts.metadataTotalDataToRead).withUnsafeBytes( { return ($0 as UnsafePointer<UInt16>).pointee })
        dataUntilNextHeader = dataUntilNextHeader * bytesPerMinute
        
        // there is a total of totalDataToRead that will come in chunks (3 or 4 bytes per minute if dataType == 1 (FUActiviyDataMode.dataLengthMinute)),
        // these chunks are usually 20 bytes long and grouped in blocks
        // after dataUntilNextHeader bytes we will get a new packet of 11 bytes that should be parsed
        // as we just did
        
        debugPrint("totalDataToRead: \(totalDataToRead), length: \(Int(totalDataToRead) / getBytesPerMinuteOfActivityData(supportHeartRate: supportHeartRate)) minute(s)")
        debugPrint("dataUntilNextHeader: \(dataUntilNextHeader), length: \(Int(dataUntilNextHeader) / getBytesPerMinuteOfActivityData(supportHeartRate: supportHeartRate)) minute(s)")
        debugPrint("timestamp: \(timestamp), magic byte: \(dataUntilNextHeader)")
    }
    
    private func handleSegment(data: Data) /*-> FUActivitySegment*/ {
        
    }
    
    private func getBytesPerMinuteOfActivityData(supportHeartRate: Bool) -> Int {
        return supportHeartRate ? 4: 3
    }
}

/*
enum FUActivityReadingState {
    case ready, reading, done
}

class FUActivityReader: NSObject {
    private(set) var activityFragments: [FUActivityDataFragment]
    var currentFragment: FUActivityDataFragment
    private(set) var state: FUActivityReadingState
    var dataIndex: Int
    var buffer: Data
    
    struct Consts {
        static let fragmentTypeRange: Range<Data.Index> = 0..<1
        static let fragmentTimestampRange: Range<Data.Index> = 1..<7
        static let fragmentDurationRange: Range<Data.Index> = 7..<9
        static let fragmentCountRange: Range<Data.Index> = 9..<11
        static let intensityRange: Range<Data.Index> = 0..<1
        static let stepsRange: Range<Data.Index> = 1..<2
        static let categoryRange: Range<Data.Index> = 2..<3
    }
    
    override var debugDescription: String {
        return "activityFragments: \(activityFragments), currentFragment: \(currentFragment), state:\(state), dataIndex: \(dataIndex), buffer: \(buffer)"
    }
    
    override init() {
        activityFragments = [FUActivityDataFragment]()
        buffer = Data()
        dataIndex = 0
        state = .ready
        currentFragment = FUActivityDataFragment()
        super.init()
    }
    
    func reloadWith(data: Data) {
        buffer.append(data)
    }
    
    func append(data: Data) {
        reloadWith(data: data)
        
        switch state {
        case .ready:
            currentFragment.type = buffer.subdata(in: Consts.fragmentTypeRange).withUnsafeBytes { return $0.pointee }
            if let tmpTimestamp = FUDateTime(data: buffer.subdata(in: Consts.fragmentTimestampRange)) {
                currentFragment.timestamp = tmpTimestamp
            } else {
                assert(false, "tmpTimestamp sall not be nil")
            }
            currentFragment.duration = buffer.subdata(in: Consts.fragmentDurationRange).withUnsafeBytes { return ($0 as UnsafePointer<UInt16>).pointee }
            currentFragment.count = buffer.subdata(in: Consts.fragmentCountRange).withUnsafeBytes { return ($0 as UnsafePointer<UInt16>).pointee }
            if (currentFragment.type == 0) {
                currentFragment.duration = currentFragment.duration / 3
                currentFragment.count = currentFragment.count / 3
            }
            if (currentFragment.count <= 0) {
                state = .done
            } else {
                state = .reading
            }
            debugPrint("[.ready] currentFragment: \(currentFragment)")
            buffer = buffer.subdata(in: 11..<buffer.count) // metadata is 11 bytes long
            break
        case .reading:
            while buffer.count >= 3 {
                currentFragment.activityDataList.append(
                    FUActivityData(intensity: buffer.subdata(in: Consts.intensityRange).withUnsafeBytes { return $0.pointee },
                                   steps: buffer.subdata(in: Consts.stepsRange).withUnsafeBytes { return $0.pointee },
                                   category: buffer.subdata(in: Consts.categoryRange).withUnsafeBytes { return $0.pointee })
                )
                buffer = buffer.subdata(in: 3..<buffer.count)   // fragment is 3 bytes long
                dataIndex = dataIndex + 1
                if dataIndex == Int(currentFragment.count) {
                    activityFragments.append(currentFragment)
                    state = .ready
                    break
                }
                debugPrint("[.reading] currentFragment: \(currentFragment)")
            }
            break
        case .done:
            debugPrint("Got .done. Do nothing")
            break
        }
    }
 
}*/
