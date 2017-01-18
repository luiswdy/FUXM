//
//  FUStatistics.swift
//  FUXM
//
//  Created by Luis Wu on 1/15/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation.NSData

class FUStatistics: CustomDebugStringConvertible, FUDataInitiable {
    var wake: UInt32        // msec
    var vibrate: UInt32     // msec
    var light: UInt32       // msec
    var conn: UInt32        // msec
    var adv: UInt32         // msec
    
    struct Consts {
        static let wakeRange: Range<Data.Index> = 0..<4
        static let vibrateRange: Range<Data.Index> = 4..<8
        static let lightRange: Range<Data.Index> = 8..<12
        static let connRange: Range<Data.Index> = 12..<16
        static let advRange: Range<Data.Index> = 16..<20
    }
    
    var debugDescription: String {
        return "wake: \(wake), vibrate: \(vibrate), light: \(light), conn: \(conn), adv: \(adv)"
    }
    
    required init?(data: Data?) {
        guard let data = data else { return nil }
        wake = data.subdata(in: Consts.wakeRange).withUnsafeBytes( { ($0 as UnsafePointer<UInt32>).pointee })
        vibrate = data.subdata(in: Consts.vibrateRange).withUnsafeBytes( { ($0 as UnsafePointer<UInt32>).pointee })
        light = data.subdata(in: Consts.lightRange).withUnsafeBytes( { ($0 as UnsafePointer<UInt32>).pointee })
        conn = data.subdata(in: Consts.connRange).withUnsafeBytes( { ($0 as UnsafePointer<UInt32>).pointee })
        adv = data.subdata(in: Consts.advRange).withUnsafeBytes( { ($0 as UnsafePointer<UInt32>).pointee })
    }
    
    init(wake: UInt32, vibrate: UInt32, light: UInt32, conn: UInt32, adv: UInt32) {
        self.wake = wake
        self.vibrate = vibrate
        self.light = light
        self.conn = conn
        self.adv = adv
    }
    
    func data() -> Data {
        var rawBytes: [UInt8] = []
        rawBytes.append(contentsOf: toUInt8Array(wake))
        rawBytes.append(contentsOf: toUInt8Array(vibrate))
        rawBytes.append(contentsOf: toUInt8Array(light))
        rawBytes.append(contentsOf: toUInt8Array(conn))
        rawBytes.append(contentsOf: toUInt8Array(adv))
        return Data(bytes: rawBytes)
    }
    
    // Convert to Data
    private func toUInt8Array<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
}
