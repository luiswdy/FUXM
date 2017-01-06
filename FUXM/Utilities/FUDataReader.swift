//
//  FUDataReader.swift
//  FUXM
//
//  Created by Luis Wu on 1/2/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

class FUDataReader {
    // Convert from Data
    static func getInt(fromData data: Data, start: Int, count: Int = 1) -> Int32 {
        let intBits = data.withUnsafeBytes({(UInt8Pointer: UnsafePointer<UInt8>) -> Int32 in
            UInt8Pointer.advanced(by: start).withMemoryRebound(to: Int32.self, capacity: MemoryLayout<Int32>.size) { pointer in
                return pointer.pointee
            }
        })
        return Int32(littleEndian: intBits)
    }
    
    static func getString(fromData data: Data, start: Int, count:Int) -> String? {
        return String(bytes: data.suffix(from: start), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func fromUInt8Array<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes{
            $0.baseAddress!.load(as: T.self)
        }
    }
    
    // Convert to Data
    func toUInt8Array<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
}
