//
//  FULEParams.swift
//  FUXM
//
//  Created by Luis Wu on 1/13/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

class FULEParams: NSObject {
    var minConnectionInterval: UInt16
    var maxConnectionInterval: UInt16
    var latency: UInt16
    var timeout: UInt16
    var advertisementInterval: UInt16
    
    struct Consts {
        static let dataLength = 12
        static let minConnectionIntervalRange: Range<Data.Index> = 0..<2
        static let maxConnectionIntervalRange: Range<Data.Index> = 2..<4
        static let latencyRange: Range<Data.Index> = 4..<6
        static let timeoutRange: Range<Data.Index> = 6..<8
        static let advertisementIntervalRange: Range<Data.Index> = 10..<12
        static let lowLatenctMinConnInterval: UInt16 = 39
        static let lowLatenctMaxConnInterval: UInt16 = 39
        static let highLatenctMinConnInterval: UInt16 = 460
        static let highLatenctMaxConnInterval: UInt16 = 500
        static let latency: UInt16 = 0
        static let advertisementInterval: UInt16 = 0
        static let timeout: UInt16 = 500    // this is minimum value allowed
    }
    
    override var debugDescription: String {
        return "minConnectionInterval: \(minConnectionInterval), "
        + "maxConnectionInterval: \(maxConnectionInterval), "
        + "latency: \(latency), "
        + "timeout: \(timeout), "
        + "advertisementInterval: \(advertisementInterval)"
    }
    
    static func lowLatencyLEParams() -> FULEParams {
        return FULEParams(minConnectionInterval: Consts.lowLatenctMinConnInterval, maxConnectionInterval: Consts.lowLatenctMaxConnInterval,
                          latency: Consts.latency, timeout: Consts.timeout, advertisementInterval: Consts.advertisementInterval)
    }
    
    static func highLatencyLEParams() -> FULEParams {
        return FULEParams(minConnectionInterval: Consts.highLatenctMinConnInterval, maxConnectionInterval: Consts.highLatenctMaxConnInterval,
                          latency: Consts.latency, timeout: Consts.timeout, advertisementInterval: Consts.advertisementInterval)
    }
    
    init(minConnectionInterval min: UInt16 = 0, maxConnectionInterval max: UInt16 = 0,
                     latency: UInt16 = 0, timeout: UInt16 = 0, advertisementInterval adv: UInt16 = 0) {
        self.minConnectionInterval = min
        self.maxConnectionInterval = max
        self.latency = latency
        self.timeout = timeout
        self.advertisementInterval = adv
    }
    
    init?(data: Data?) {
        if let data = data, data.count == Consts.dataLength {
            self.minConnectionInterval = data.subdata(in: Consts.minConnectionIntervalRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
            self.maxConnectionInterval = data.subdata(in: Consts.maxConnectionIntervalRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
            self.latency = data.subdata(in: Consts.latencyRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
            self.timeout = data.subdata(in: Consts.timeoutRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
            self.advertisementInterval = data.subdata(in: Consts.advertisementIntervalRange).withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
                return pointer.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee })
            }
        } else {
            return nil
        }
    }
    
    func data() -> Data {
        var bytes = [UInt8](repeating: 0, count: 12)
        bytes[0] = UInt8(truncatingBitPattern: self.minConnectionInterval)
        bytes[1] = UInt8(truncatingBitPattern: self.minConnectionInterval >> 8)
        bytes[2] = UInt8(truncatingBitPattern: self.maxConnectionInterval)
        bytes[3] = UInt8(truncatingBitPattern: self.maxConnectionInterval >> 8)
        bytes[4] = UInt8(truncatingBitPattern: latency)
        bytes[5] = UInt8(truncatingBitPattern: latency >> 8)
        bytes[6] = UInt8(truncatingBitPattern: timeout)
        bytes[7] = UInt8(truncatingBitPattern: timeout >> 8)
        bytes[8] = 0
        bytes[9] = 0
        bytes[10] = UInt8(truncatingBitPattern: advertisementInterval)
        bytes[11] = UInt8(truncatingBitPattern: advertisementInterval >> 8)
        return Data(bytes: bytes)
    }
}
