//
//  FUUserInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation.NSData

enum FUGender: UInt8 {
    case
    female = 0,
    male
}
enum FUAuthType: UInt8 {
    case
    normal = 0,
    clearData,
    retainData
}

class FUUserInfo: CustomDebugStringConvertible, FUDataInitiable {
    private struct Consts {
        static let incomingUserInfoLength: Int = 19
        static let uidRange: Range<Data.Index> = 0..<4
        static let genderRange: Range<Data.Index> = 4..<5
        static let ageRange: Range<Data.Index> = 5..<6
        static let heightRange: Range<Data.Index> = 6..<7
        static let weightRange: Range<Data.Index> = 7..<8
        static let typeRange: Range<Data.Index> = 8..<9
        static let aliasRange: Range<Data.Index> = 9..<incomingUserInfoLength
    }
    
    private(set) var uid: UInt32
    private(set) var gender: FUGender
    private(set) var age: UInt8
    private(set) var height: UInt8
    private(set) var weight: UInt8
    private(set) var type: FUAuthType
    private(set) var alias: String
    
    var debugDescription: String {
        return "uid: \(uid), "
            + "gender: \(gender), "
            + "age: \(age), "
            + "height: \(height), "
            + "weight: \(weight), "
            + "type: \(type), "
            + "alias: \(alias)"
    }
    
    init(uid: UInt32 = 0, gender: FUGender = .female, age: UInt8 = 0,
         height:UInt8 = 0, weight:UInt8 = 0, type: FUAuthType = .normal,
         alias: String = "") {
        self.uid = uid
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.type = type
        self.alias = alias
    }
    
    required convenience init(data: Data?) {
        self.init()
        parseData(data)
    }
    
    func data(salt: UInt8) -> Data {
        return toData(salt: salt)
    }
    
    // MARK - private
    private func parseData(_ data: Data?){
        guard let data = data else { return }
        guard data.count > Consts.incomingUserInfoLength else { return }
        self.uid = data.subdata(in: Consts.uidRange).withUnsafeBytes( { return UInt32((($0.pointee) as UInt32).bigEndian) } )
        let gender: FUGender? = data.subdata(in: Consts.genderRange).withUnsafeBytes( { return FUGender(rawValue: $0.pointee) } )
        if let gender = gender { self.gender = gender }
        self.age = data.subdata(in: Consts.ageRange).withUnsafeBytes( { return $0.pointee } )
        self.height = data.subdata(in: Consts.heightRange).withUnsafeBytes( { return $0.pointee } )
        self.weight = data.subdata(in: Consts.weightRange).withUnsafeBytes( { return $0.pointee } )
        self.alias = data.subdata(in: Consts.aliasRange).withUnsafeBytes( { return $0.pointee } )
    }
    
    private func toData(salt: UInt8) -> Data {
        var bytes: [UInt8] = []
        bytes.append(UInt8(truncatingBitPattern: self.uid.bigEndian))
        bytes.append(UInt8(truncatingBitPattern: self.uid.bigEndian >> 8))
        bytes.append(UInt8(truncatingBitPattern: self.uid.bigEndian >> 16))
        bytes.append(UInt8(truncatingBitPattern: self.uid.bigEndian >> 24))
        bytes.append(self.gender.rawValue)
        bytes.append(self.age)
        bytes.append(self.height)
        bytes.append(self.weight)
        bytes.append(self.type.rawValue)
        bytes.append(contentsOf:Array(alias.utf8))
        let paddingCount = Consts.incomingUserInfoLength - bytes.count
        if  paddingCount > 0  {
            bytes.append(contentsOf: Array<UInt8>(repeating:UInt8(0), count:paddingCount))
        }
        bytes.append(checksum(bytes: bytes, from: 0, length: Consts.incomingUserInfoLength, lastMACByte:salt))
        // TODO not mili 1
        return Data(bytes: bytes)
    }
    
    private func checksum(bytes: [UInt8],from index: Int, length: Int, lastMACByte: UInt8) -> UInt8 {
        let input = Array<UInt8>(bytes[index ..< bytes.count])
        let crc = FUCRC8Util.crc8WithBytes(bytes: input, length: length)
        return crc ^ 0xff & lastMACByte
    }
}
