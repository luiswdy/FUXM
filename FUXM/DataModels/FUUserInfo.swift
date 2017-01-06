//
//  FUUserInfo.swift
//  FUXM
//
//  Created by Luis Wu on 1/2/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

public enum FUGender: UInt {
    case female = 0, male
}

public enum FUAuthType: UInt {
    case normal = 0, clearData, RetainData
}

public class FUUserInfo {
    // public properties
    public var uid: UInt
    public var gender: FUGender
    public var age: UInt
    public var height: UInt
    public var weight: UInt
    public var alias: String    // name
    public var type: FUAuthType
    
    required public init() {
        self.uid = 0
        self.gender = .female
        self.age = 0
        self.height = 0
        self.weight = 0
        self.alias = ""
        self.type = .normal
    }
    
    public func initFrom(data: Data) {
        self.uid = UInt(FUDataReader.getInt(fromData: data, start: 0, count: 4))  // UInt8 0 ~ 3
//        self.uid = data.subdata(in: 0 ..< 4)
        self.gender = FUGender(rawValue: UInt(FUDataReader.getInt(fromData: data, start: 4)))!  // UInt8 4
        self.age = UInt(FUDataReader.getInt(fromData: data, start: 5))    // UInt8 5
        self.height = UInt(FUDataReader.getInt(fromData: data, start: 6))    //UInt8 6
        self.weight = UInt(FUDataReader.getInt(fromData: data, start: 7))    //UInt87
        self.type = FUAuthType(rawValue:UInt(FUDataReader.getInt(fromData: data, start: 8)))!    //UInt8 8
        self.alias = FUDataReader.getString(fromData: data, start: 9, count: 8)!
    }
    
    public func initWith(name: String, uid: UInt, gender: FUGender, age: UInt, height: UInt, weight: UInt, type: FUAuthType) {
        self.alias = name
        self.uid = uid
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.type = type
    }
    
}
