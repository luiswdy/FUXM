//
//  FUActivityReader.swift
//  FUXM
//
//  Created by Luis Wu on 1/16/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation.NSData
import RxSwift

enum FUActivityReadingState: Int {
    case
    initial = 0,    // waiting for metadata
    reading,        // reading data
    done            // read all data
}

enum FUActivityDataMode: Int {
    case dataLengthByte = 0, dataLengthMinute = 1
}

class FUActivityReader: CustomDebugStringConvertible {
    var metadata: FUActivityMetadata
    var activities: [FUActivity]
    var buffer: Data
    var state = FUActivityReadingState.initial
    let supportHeartRate: Bool
    
    private struct Consts {
        static let activityMetadataLength = 11
        static let metadataTypeRange: Range<Data.Index> = 0..<1
        static let metadatatimestampRange: Range<Data.Index> = 1..<7
        static let metadataTotalDataToReadRange: Range<Data.Index> = 7..<9
        static let metadataDataUntilNextHeaderRange: Range<Data.Index> = 9..<11
    }
    
    var debugDescription: String {
        return "TODO"
    }
    
    init(supportHeartRate: Bool) {
        self.metadata = FUActivityMetadata()
        self.activities = []
        self.buffer = Data()
        self.supportHeartRate = supportHeartRate
    }
    
    func handleIncomingData(_ data: Data?) -> Observable<[FUActivity]> {
        return Observable.create({ (observer) -> Disposable in
            objc_sync_enter(self.buffer)
            
            debugPrint("\(Date()) - data.count = \(data?.count)")
            
            if let data = data, data.count == Consts.activityMetadataLength {
//                assert(self.state == .initial, "why got metadata if it's not done?")
                
                self.metadata = self.handleMetadata(data: data, supportHeartRate: self.supportHeartRate)
                self.state = .reading
            } else if let data = data, self.state == .reading {
//                assert(self.state == .reading, "why not reading?")
                self.buffer.append(data)
//                self.handleData(data: data)
                if self.buffer.count == Int(self.metadata.dataUntilNextHeader) {
                    self.convertBufferIntoActivities(baseTimestamp: self.metadata.timestamp)
                    observer.on(.next(Array(self.activities))) // onNext when a chunk is loaded (TODO)
                    observer.on(.completed) // onCompleted when on more data to load
                    self.state = .done      // end of the chunk
                    assert(self.metadata.dataUntilNextHeader >= 0, "dataUntilNextHeader < 0. why?")
                }
            } else {
                // do nothing
//                assertionFailure("Should not get here")
            }
            objc_sync_exit(self.buffer)
            return Disposables.create() // no-op
        })
    }
    
    private func handleMetadata(data: Data, supportHeartRate: Bool) -> FUActivityMetadata {
        // byte 0 is the data type: 1 means that each minute is represented by a triplet of bytes
        
        let dataType: FUActivityDataMode = FUActivityDataMode(rawValue: data.subdata(in: Consts.metadataTypeRange).withUnsafeBytes( { return $0.pointee } )) != nil ? FUActivityDataMode(rawValue: data.subdata(in: Consts.metadataTypeRange).withUnsafeBytes( { return $0.pointee } ))! : .dataLengthByte
        // bytes 1 ~ 6 represents a timestamp
        let timestamp = FUDateTime(data: data.subdata(in: Consts.metadatatimestampRange))
        // counter for all data held by the band
        var totalDataToRead = data.subdata(in: Consts.metadataTotalDataToReadRange).withUnsafeBytes( { return ($0 as UnsafePointer<UInt16>).pointee })
        let bytesPerMinute = UInt16(dataType == .dataLengthMinute ? getBytesPerMinuteOfActivityData(supportHeartRate: supportHeartRate) : 1)
        totalDataToRead = totalDataToRead * bytesPerMinute
        // counter of this data block
        var dataUntilNextHeader = data.subdata(in: Consts.metadataDataUntilNextHeaderRange).withUnsafeBytes( { return ($0 as UnsafePointer<UInt16>).pointee })
        dataUntilNextHeader = dataUntilNextHeader * bytesPerMinute
        
        // there is a total of totalDataToRead that will come in chunks (3 or 4 bytes per minute if dataType == 1 (FUActiviyDataMode.dataLengthMinute)),
        // these chunks are usually 20 bytes long and grouped in blocks
        // after dataUntilNextHeader bytes we will get a new packet of 11 bytes that should be parsed
        // as we just did
        
        debugPrint("totalDataToRead: \(totalDataToRead), length: \(Int(totalDataToRead) / getBytesPerMinuteOfActivityData(supportHeartRate: supportHeartRate)) minute(s)")
        debugPrint("dataUntilNextHeader: \(dataUntilNextHeader), length: \(Int(dataUntilNextHeader) / getBytesPerMinuteOfActivityData(supportHeartRate: supportHeartRate)) minute(s)")
        debugPrint("timestamp: \(timestamp), magic byte: \(dataUntilNextHeader)")
        metadata.dataType = dataType
        if let dateTime = timestamp?.toDate() {
            metadata.timestamp = dateTime
        }
        metadata.totalDataToRead = totalDataToRead
        metadata.dataUntilNextHeader = dataUntilNextHeader
        let convertedtimestamp = timestamp?.toDate() != nil ? timestamp!.toDate()! : Date.distantPast
        return FUActivityMetadata(dataType: dataType, timestamp: convertedtimestamp, totalDataToRead: totalDataToRead, bytesPerMinute: bytesPerMinute, dataUntilNextHeader: dataUntilNextHeader)
    }
    
    private func getBytesPerMinuteOfActivityData(supportHeartRate: Bool) -> Int {
        return supportHeartRate ? 4 : 3
    }
    
    private func convertBufferIntoActivities(baseTimestamp: Date) {
            objc_sync_enter(self.buffer)
        assert(buffer.count % getBytesPerMinuteOfActivityData(supportHeartRate: self.supportHeartRate) == 0, "something is wrong")
        var minuteOffset = 0
        while buffer.count > 0 {
            let activity = buffer.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> FUActivity in
                let timestamp = baseTimestamp.addingTimeInterval( TimeInterval(60 * minuteOffset) )
                debugPrint("DEBUG: category = \(Int8(pointer.pointee))")
                let category = FUActivityCategory(rawValue: Int8(pointer.pointee))  == nil ? FUActivityCategory.activity : FUActivityCategory(rawValue: Int8(pointer.pointee))!
                let intensity = pointer.advanced(by: 1).pointee
                let steps = pointer.advanced(by: 2).pointee
                var heartRate: UInt8? = nil
                if supportHeartRate {
                    heartRate = pointer.advanced(by: 3).pointee
                }
                return FUActivity(timestamp: timestamp, category: category, intensity: intensity, steps: steps, heartRate: heartRate)
            })
            self.activities.append(activity)
            minuteOffset = minuteOffset + 1
//            buffer = buffer.subdata(in: getBytesPerMinuteOfActivityData(supportHeartRate: self.supportHeartRate) ..< buffer.count)
            buffer.removeFirst(getBytesPerMinuteOfActivityData(supportHeartRate: self.supportHeartRate))
        }
            objc_sync_exit(self.buffer)
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
        static let fragmenttimestampRange: Range<Data.Index> = 1..<7
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
            if let tmptimestamp = FUDateTime(data: buffer.subdata(in: Consts.fragmenttimestampRange)) {
                currentFragment.timestamp = tmptimestamp
            } else {
                assert(false, "tmptimestamp sall not be nil")
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
