//
//  FUDeviceInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

class FUDeviceInfo: NSObject {
    let deviceID: String
    let mac: String
    let salt: UInt8
    let profileVer: String
    let firmwareVer: String
    let feature: Int
    let appearance: Int
    let hardwareVer: Int
    
    // heart rate firmware version identifier
    let firmware2Ver: Int32
    let test1AHeartRateMode: Bool
    
    override var debugDescription: String {
        return "deviceID: \(deviceID), "
            + "MAC: \(mac), "
            + "salt: \(salt), "
            + "profileVer: \(profileVer), "
            + "firmwareVer: \(firmwareVer), "
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
        static let firmwareVerMinorOffset = 1
        static let firmwareVerBuildOffset = 2
        static let firmwareVerRevisionOffset = 3
        static let firmwareVer2Range: Range<Data.Index> = 16..<20
        static let featureRange: Range<Data.Index> = 4..<5
        static let appearanceRange: Range<Data.Index> = 5..<6
        static let hardwareVerRange: Range<Data.Index> = 6..<7
        static let verFormatString = "%d.%d.%d.%d"
        
        static let validDataLength16 = 16
        static let validDataLength20 = 20
    }
    
    required init?(data: Data?) {   // failable initializer
        guard let data = data else {
            return nil
        }
        
        
        if (data.count == Consts.validDataLength16
            || data.count == Consts.validDataLength20)
            && FUDeviceInfo.isChecksumCorrect(data: data) {
            let deviceIDInInt32 = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes({(pointer: UnsafePointer<Int8>) -> Int32 in
                pointer.withMemoryRebound(to: Int32.self, capacity: MemoryLayout<Int32>.size) { pointer in
                    return pointer.pointee
                }
            })
            deviceID = String(deviceIDInInt32.bigEndian,
                              radix:GlobalConsts.hexRadix,
                              uppercase: false
            )
            mac = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes { (pointer: UnsafePointer<Int8>) -> String in
                return String(format: Consts.macFormatString, pointer.pointee,
                              Consts.fixedMACAddressSection2,
                              Consts.fixedMACAddressSection3,
                              pointer.advanced(by: Consts.section4MACOffset).pointee,
                              pointer.advanced(by: Consts.section5MACOffset).pointee,
                              pointer.advanced(by: Consts.section6MACOffset).pointee)
            }
            salt = data.subdata(in: Consts.deviceIDRange).withUnsafeBytes {return $0.advanced(by: Consts.saltOffset).pointee}
            profileVer = Data(bytes: data.subdata(in: Consts.profileVerRange).reversed())
                .withUnsafeBytes({ (pointer: UnsafePointer<Int8>) -> String in
                    String(format:Consts.verFormatString, pointer.pointee,   // major
                        pointer.advanced(by: Consts.profileVerMinorOffset).pointee,
                        pointer.advanced(by: Consts.profileVerBuildOffset).pointee,
                        pointer.advanced(by: Consts.profileVerRevisionOffset).pointee)
                })
            firmwareVer = Data(bytes: data.subdata(in: Consts.firmwareVerRange).reversed())
                .withUnsafeBytes({ (pointer: UnsafePointer<Int8>) -> String in
                    String(format:Consts.verFormatString, pointer.pointee,   // major
                        pointer.advanced(by: Consts.firmwareVerMinorOffset).pointee,
                        pointer.advanced(by: Consts.firmwareVerBuildOffset).pointee,
                        pointer.advanced(by: Consts.firmwareVerRevisionOffset).pointee)
                })
            feature = data.subdata(in: Consts.featureRange).withUnsafeBytes { return $0.pointee }
            appearance = data.subdata(in: Consts.appearanceRange).withUnsafeBytes { return $0.pointee }
            hardwareVer = data.subdata(in: Consts.hardwareVerRange).withUnsafeBytes { return $0.pointee }
            
            if (data.count == Consts.validDataLength20) {
                firmware2Ver = data.subdata(in: Consts.firmwareVer2Range).withUnsafeBytes( { return ($0 as UnsafePointer<Int32>).pointee } )
            } else {
                firmware2Ver = -1
            }
            test1AHeartRateMode = false
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
    
    // MARK - private methods
    private static func isChecksumCorrect(data: Data?) -> Bool {
        guard let data = data else { return false }
        let crc8 = FUCRC8Util.crc8WithBytes(bytes: [UInt8](data), length: data.count)
        return (data.withUnsafeBytes( { return $0.advanced(by: 7).pointee }) & 0xff) == (crc8 ^ data.withUnsafeBytes( { return $0.advanced(by: 3).pointee }) & 0xff)
    }
}
