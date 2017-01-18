//
//  FUCRC8Util.swift
//  FUXM
//
//  Created by Luis Wu on 1/16/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

class FUCRC8Util {
    static func crc8WithBytes(bytes: [UInt8], length: Int) -> UInt8 {
        var checksum: UInt8 = 0
        for i in 0 ..< length {
            checksum ^= bytes[i]
            for _ in 0 ..< 8 {
                if (checksum & 0x1 as UInt8) > 0 {
                    checksum = (0x8c ^ (0xff & checksum >> 1))
                } else {
                    checksum = (0xff & checksum >> 1)
                }
            }
        }
        return checksum
    }
}
