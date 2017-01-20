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
    case dataLengthByte = 0,
    dataLengthMinute = 1
}

class FUActivityReader: CustomDebugStringConvertible {
    var metadata: FUActivityMetadata?
    var activities: [FUActivity]
    var buffer: Data
    var state = FUActivityReadingState.initial
    let supportHeartRate: Bool
    
    var debugDescription: String {
        return "metadata: \(metadata), activities: \(activities)"
    }
    
    struct Consts {
        static let OneMinute: TimeInterval = 60
    }
    
    init(supportHeartRate: Bool) {
        self.activities = []
        self.buffer = Data()
        self.supportHeartRate = supportHeartRate
    }
    
    func handleIncomingData(_ data: Data?) -> Observable<[FUActivity]> {
        return Observable.create({ (observer) -> Disposable in
            objc_sync_enter(self.buffer)
            debugPrint("data.count = \(data?.count)")
            if let data = data, data.count == FUActivityMetadata.metadataLength,
                let metadata = FUActivityMetadata(data: data, isSupportHeartRate: self.supportHeartRate) {
                self.metadata = metadata
                self.state = .reading
            } else if let data = data, self.state == .reading {
                assert(self.state == .reading, "why not reading?")
                assert(self.metadata != nil, "metadata should be ready at this point")
                self.buffer.append(data)
                if self.buffer.count == Int(self.metadata!.dataUntilNextHeader) {
                    self.convertBufferIntoActivities(baseTimestamp: self.metadata!.timestamp)
                    observer.on(.next(Array(self.activities)))
                    observer.on(.completed)
                    self.state = .done  // end of the chunk
                    assert(self.metadata!.dataUntilNextHeader >= 0, "dataUntilNextHeader < 0. why?")
                }
            } else {
                assertionFailure("Should not get here")
            }
            objc_sync_exit(self.buffer)
            return Disposables.create() // no-op
        })
    }
    
    private func convertBufferIntoActivities(baseTimestamp: Date) {
        objc_sync_enter(self.buffer)
        assert(metadata != nil, "metadata should be ready at this point")
        assert(buffer.count % Int(metadata!.bytesPerMinute) == 0, "incoming data must be multiple of \(metadata!.bytesPerMinute)")
        var minuteOffset = 0
        while buffer.count > 0 {
            if let activity = buffer.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> FUActivity? in
                let timestamp = baseTimestamp.addingTimeInterval( TimeInterval(minuteOffset) * Consts.OneMinute )
                return FUActivity(timestamp: timestamp, isSupportHeartRate: self.supportHeartRate, data: buffer.subdata(in: 0..<metadata!.bytesPerMinute))
            }) {
                self.activities.append(activity)
                minuteOffset = minuteOffset + 1
                buffer.removeFirst(metadata!.bytesPerMinute)
            } else {
                assertionFailure("Suppose to get valid activity")
            }
        }
        objc_sync_exit(self.buffer)
    }
}
