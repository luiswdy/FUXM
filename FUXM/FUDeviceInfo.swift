//
//  FUDeviceInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

class FUDeviceInfo: NSObject {
    private(set) var deviceID: String
    private(set) var mac: String
    private(set) var salt: UInt8
    private(set) var profileVer: String
    private(set) var firmwareVer: String
    let feature: UInt
    let appearance: UInt
    let hardwareVer: UInt
    
    override var description: String {
        return "deviceID: \(deviceID), "
            + "MAC: \(mac), "
            + "salt: \(salt), "
            + "profileVer: \(profileVer), "
            + "firmwareVer: \(firmwareVer), "
            + "feature: \(feature)"
    }

    struct Consts {
        static let deviceIDRange: Range<Data.Index> = 0..<7
        static let macFormatString = "%x:%s:%x:%x:%x"
        static let fixedMACAddressPortion = "0F:10"
        static let section4MACOffset = 1
        static let section5MACOffset = 2
        static let section6MACOffset = 3
        static let saltOffset = section6MACOffset
        static let profileVerRange: Range<Data.Index> = 8..<12
        static let profileVerMinorOffset = 1
        static let profileVerBuildOffset = 2
        static let profileVerRevisionOffset = 3
        static let firmwareVerRange: Range<Data.Index> = 12..<16
        static let firmwareVerMinorOffset = 1
        static let firmwareVerBuildOffset = 2
        static let firmwareVerRevisionOffset = 3
        static let featureRange: Range<Data.Index> = 4..<5
        static let appearanceRange: Range<Data.Index> = 5..<6
        static let hardwareVerRange: Range<Data.Index> = 6..<7
        static let verFormatString = "%d.%d.%d.%d"
    }
    
    required init?(data: Data?) {   // failable initializer
        guard let data = data else {
            return nil
        }
        let deviceIDInInt32 = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes({(pointer: UnsafePointer<UInt8>) -> Int32 in
            pointer.withMemoryRebound(to: Int32.self, capacity: MemoryLayout<Int32>.size) { pointer in
                return pointer.pointee
            }
        })
        deviceID = String(deviceIDInInt32,
                          radix:GlobalConsts.hexRadix,
                          uppercase: false
        )
        mac = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> String in
            return String(format: Consts.macFormatString, pointer.pointee,
                          Consts.fixedMACAddressPortion,
                          pointer.advanced(by: Consts.section4MACOffset).pointee,
                          pointer.advanced(by: Consts.section5MACOffset).pointee,
                          pointer.advanced(by: Consts.section6MACOffset).pointee)
        }
        salt = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes {return $0.advanced(by: Consts.saltOffset).pointee}
        profileVer = Data(bytes: (data.subdata(in: Consts.profileVerRange).reversed() as [UInt8]))
            .withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> String in
                String(format:Consts.verFormatString, pointer.pointee,   // major
                       pointer.advanced(by: Consts.profileVerMinorOffset).pointee,
                       pointer.advanced(by: Consts.profileVerBuildOffset).pointee,
                       pointer.advanced(by: Consts.profileVerRevisionOffset))
        })
        firmwareVer = Data(bytes: (data.subdata(in: Consts.firmwareVerRange).reversed() as [UInt8]))
            .withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> String in
                String(format:Consts.verFormatString, pointer.pointee,   // major
                       pointer.advanced(by: Consts.firmwareVerMinorOffset).pointee,
                       pointer.advanced(by: Consts.firmwareVerBuildOffset).pointee,
                       pointer.advanced(by: Consts.firmwareVerRevisionOffset))
        })
        feature = data.subdata(in: Consts.featureRange).withUnsafeBytes { return $0.pointee }
        appearance = data.subdata(in: Consts.appearanceRange).withUnsafeBytes { return $0.pointee }
        hardwareVer = data.subdata(in: Consts.hardwareVerRange).withUnsafeBytes { return $0.pointee }
    }
    
}
