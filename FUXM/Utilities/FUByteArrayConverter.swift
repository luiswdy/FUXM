//
//  FUByteArrayConverter.swift
//  FUXM
//
//  Created by Luis Wu on 1/2/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

class FUByteArrayConverter {
    // Convert from Data
    static func fromUInt8Array<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes{
            $0.baseAddress!.load(as: T.self)
        }
    }
    
    // Convert to Data
    static func toUInt8Array<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
}
