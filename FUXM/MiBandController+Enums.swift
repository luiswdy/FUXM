//
//  MiBandController+Enums.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation

extension MiBandController {
    // Mi band services
    enum FUServiceUUID: UInt16 {  // 2 bytes, little endian. NOTE: UInt8 servers as a byte in Swift
        case
        ias         = 0x1802,
        miBand      = 0xfee0,
        miBand2     = 0xfee1,
        unknown     = 0xfee7
        
        static let allValues = [miBand, miBand2, unknown, ias]
        static let allKeys = [ "\(ias)", "\(miBand)", "\(miBand2)", "\(unknown)"]
    }
    
    // Mi band characteristics
    enum FUCharacteristicUUID: UInt16 {   // 2 bytes, little endian
        case
        // characteristics of service immediateAlert (IAS)
        alertLevel      = 0x2a06,
        // characteristics of service miBand
        deviceInfo      = 0xff01,
        deviceName      = 0xff02,
        notification    = 0xff03,
        userInfo        = 0xff04,
        controlPoint    = 0xff05,
        realtimeSteps   = 0xff06,
        activityData    = 0xff07,
        firmwareData    = 0xff08,
        leParams        = 0xff09,
        dateTime        = 0xff0a,
        statistics      = 0xff0b,
        battery         = 0xff0c,
        test            = 0xff0d,
        sensorData      = 0xff0e,
        pair            = 0xff0f,
        weird           = 0xff10,           // something didn't appear or explain by my reference source. I remember I got this from keep shaking my mi band. Should figure when this appear and its value
        // characteristics of service miBand2
        unknown1        = 0xfedd,
        unknown2        = 0xfede,
        unknown3        = 0xfedf,
        unknown4        = 0xfee0,
        unknown5        = 0xfee1,
        unknown6        = 0xfee2,
        unknown7        = 0xfee3,
        unknown8        = 0xfec7,  // characteristics of unknown service
        unknown9        = 0xfec8,
        macAddress      = 0xfec9,
        unknown11       = 0xfed0,
        unknown12       = 0xfed1
        
        // characteristics - IAS
        static let iasCharacteristics = [alertLevel]
        static let iasCharacteristicKeys = [ "\(alertLevel)"]
        // characteristics - miband service
        static let miBandCharacteristics = [deviceInfo, deviceName, notification, userInfo,
                                            controlPoint, realtimeSteps, activityData, firmwareData,
                                            leParams, dateTime, statistics, battery, test, sensorData,
                                            pair]
        static let miBandCharacteristicKeys = ["\(deviceInfo)", "\(deviceName)", "\(notification)",
            "\(userInfo)", "\(controlPoint)", "\(realtimeSteps)", "\(activityData)", "\(firmwareData)",
            "\(leParams)", "\(dateTime)", "\(statistics)", "\(battery)",
            "\(test)", "\(sensorData)", "\(pair)"]
        // characteristics - miband 2 service
        static let miBand2Characteristics = [unknown1, unknown2, unknown3, unknown4, unknown5, unknown6, unknown7]
        static let miBand2CharacteristicKeys = ["\(unknown1)", "\(unknown2)", "\(unknown3)", "\(unknown4)",
            "\(unknown5)", "\(unknown6)", "\(unknown7)"]
        // characteristics - unknown service
        static let unknownCharacteristics = [unknown8, unknown9, macAddress]
        static let unknownCharacteristicKeys = ["\(unknown8)", "\(unknown9)", "\(macAddress)"]
        // all values
        static let allValues: [FUCharacteristicUUID] = FUCharacteristicUUID.iasCharacteristics
            + FUCharacteristicUUID.miBandCharacteristics
            + FUCharacteristicUUID.miBand2Characteristics
            + FUCharacteristicUUID.unknownCharacteristics
        static let allKeys: [String] = FUCharacteristicUUID.iasCharacteristicKeys
            + FUCharacteristicUUID.miBandCharacteristicKeys
            + FUCharacteristicUUID.miBand2CharacteristicKeys
            + FUCharacteristicUUID.unknownCharacteristicKeys
        static let notifiableCharacteristics = [ notification, realtimeSteps, activityData, battery, sensorData, leParams ]
        
    }
    
    enum FUActivityType: Int8 {
        case
        activity    = -1,
        nonWear     = 3,
        deepSleep   = 4,
        lightSleep  = 5,
        charging    = 6
    }
    
    enum ControlPointCommand: UInt8 {
        case
        setHeartRateSleep                   = 0x0,  // TODO
        setHeartRateContinuous              = 0x1,  // TODO
        setHeartRateManual                  = 0x2,  // TODO
        setRealtimeStepNotification         = 0x3,
        setTimer                            = 0x4,
        setFitnessGoal                      = 0x5,
        fetchData                           = 0x6,
        firmwareInfo                        = 0x7,
        sendNotification                    = 0x8,
//        factoryReset                        = 0x9,    // no logner in-use
        confirmActivityDataTransferComplete = 0xa,
        sync                                = 0xb,
        reboot                              = 0xc,
        setColorTheme                       = 0xe,
        setWearPosition                     = 0xf,
//        setRealtimeSteps                    = 0x10, // no longer in-use
        stopSyncData                        = 0x11,
        getSensorData                       = 0x12,
        stopMotorVibrate                    = 0x13
    }
    
    enum PairCommand: UInt16 {
        case pair = 0x2, unpair = 0xfff
    }
}
