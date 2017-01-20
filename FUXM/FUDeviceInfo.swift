//
//  FUDeviceInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation.NSData

class FUDeviceInfo: CustomDebugStringConvertible, FUDataInitiable {
    let deviceID: String
    let mac: String
    let salt: UInt8
    let profileVer: String
    //    let firmwareVer: String
    let firmwareVer: UInt32
    let firmwareVer2: UInt32
    let feature: UInt
    let appearance: UInt
    let hardwareVer: UInt
    var test1AHeartRateMode = false // set this as default
    
    var debugDescription: String {
        return "deviceID: \(deviceID), "
            + "MAC: \(mac), "
            + "salt: \(salt), "
            + "profileVer: \(profileVer), "
            + "firmwareVer: \(firmwareVer), "
            + "firmwareVer2: \(firmwareVer2), "
            + "feature: \(feature), "
            + "appearance: \(appearance), "
            + "hardwareVer: \(hardwareVer)"
    }
    
    private struct Consts {
        static let deviceIDRange: Range<Data.Index> = 0..<7
        static let macFormatString = "%02x:%02x:%02x:%02x:%02x:%02x"
        static let fixedMACAddressSection2 = 0x0f
        static let fixedMACAddressSection3 = 0x10
        static let section4MACOffset = 1
        static let section5MACOffset = 2
        static let section6MACOffset = 3
        static let saltOffset = section6MACOffset
        static let profileVerRange: Range<Data.Index> = 8..<12
        static let profileVerMinorOffset = 1
        static let profileVerBuildOffset = 2
        static let profileVerRevisionOffset = 3
        static let firmwareVerRange: Range<Data.Index> = 12..<16
        static let firmwareVer2Range: Range<Data.Index> = 16..<20
        static let firmwareVerMinorOffset = 1
        static let firmwareVerBuildOffset = 2
        static let firmwareVerRevisionOffset = 3
        static let featureRange: Range<Data.Index> = 4..<5
        static let appearanceRange: Range<Data.Index> = 5..<6
        static let hardwareVerRange: Range<Data.Index> = 6..<7
        static let verFormatString = "%d.%d.%d.%d"
        static let standardDataLength = 16
        static let extendedDataLength = 20
    }
    
    required init?(data: Data?) {   // failable initializer
        guard let data = data else {
            return nil
        }
        if data.count == Consts.standardDataLength || data.count == Consts.extendedDataLength {
            let deviceIDInUInt32 = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes({(pointer: UnsafePointer<UInt8>) -> UInt32 in
                pointer.withMemoryRebound(to: UInt32.self, capacity: MemoryLayout<UInt32>.size) { pointer in
                    return pointer.pointee
                }
            })
            deviceID = String(deviceIDInUInt32.bigEndian,
                              radix:GlobalConsts.hexRadix,
                              uppercase: false
            )
            mac = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> String in
                return String(format: Consts.macFormatString, pointer.pointee,
                              Consts.fixedMACAddressSection2,
                              Consts.fixedMACAddressSection3,
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
                        pointer.advanced(by: Consts.profileVerRevisionOffset).pointee)
                })
            firmwareVer = data.subdata(in: Consts.firmwareVerRange).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt32 in
                return pointer.withMemoryRebound(to: UInt32.self, capacity: MemoryLayout<UInt32>.size, { (pointer: UnsafePointer<UInt32>) -> UInt32 in
                    return pointer.pointee
                })
            })
            feature = data.subdata(in: Consts.featureRange).withUnsafeBytes { return $0.pointee }
            appearance = data.subdata(in: Consts.appearanceRange).withUnsafeBytes { return $0.pointee }
            hardwareVer = data.subdata(in: Consts.hardwareVerRange).withUnsafeBytes { return $0.pointee }
            if data.count == Consts.extendedDataLength {
                firmwareVer2 = data.subdata(in: Consts.firmwareVer2Range).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt32 in
                    return pointer.withMemoryRebound(to: UInt32.self, capacity: MemoryLayout<UInt32>.size, { (pointer: UnsafePointer<UInt32>) -> UInt32 in
                        return pointer.pointee
                    })
                })
            } else {
                firmwareVer2 = 0
            }
        } else {
            return nil
        }
    }
    
    func isMili1() -> Bool {
        return hardwareVer == 2
    }
    
    func isMili1A() -> Bool {
        return feature == 5 && appearance == 0 || feature == 0 && hardwareVer == 208
    }
    
    func isMili1S() -> Bool {   // with LED heart rate sensor
        // TODO: this is probably not quite correct, but hopefully sufficient for early 1S support
        return (feature == 4 && appearance == 0) || hardwareVer == 4
    }
    
    func supportHeartRate() -> Bool {
        return isMili1S() || test1AHeartRateMode && isMili1A()
    }
    
    func getHeartRateFirmwareVer() -> UInt32 {
        if (test1AHeartRateMode) {
            return firmwareVer
        }
        return firmwareVer2
    }
    
    // MARK - private methods
    private static func isChecksumCorrect(data: Data?) -> Bool {
        guard let data = data else { return false }
        let crc8 = FUCRC8Util.crc8WithBytes(bytes: [UInt8](data), length: data.count)
        return (data.withUnsafeBytes( { return $0.advanced(by: 7).pointee }) & 0xff) == (crc8 ^ data.withUnsafeBytes( { return $0.advanced(by: 3).pointee }) & 0xff)
    }
}
