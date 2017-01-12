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
        unknown10       = 0xfec9
        
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
        static let unknownCharacteristics = [unknown8, unknown9, unknown10]
        static let unknownCharacteristicKeys = ["\(unknown8)", "\(unknown9)", "\(unknown10)"]
        // all values
        static let allValues: [FUCharacteristicUUID] = FUCharacteristicUUID.iasCharacteristics
            + FUCharacteristicUUID.miBandCharacteristics
            + FUCharacteristicUUID.miBand2Characteristics
            + FUCharacteristicUUID.unknownCharacteristics
        static let allKeys: [String] = FUCharacteristicUUID.iasCharacteristicKeys
            + FUCharacteristicUUID.miBandCharacteristicKeys
            + FUCharacteristicUUID.miBand2CharacteristicKeys
            + FUCharacteristicUUID.unknownCharacteristicKeys
        
    }
    
    // Values may receive from
    // optional func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    // after setNotify to characteristic notification (0xff03)
    enum FUNotification: UInt8 {
        case
        //    unknown = -0x1,
        normal                  = 0x0,
        firmwareUpdateFailed    = 0x1,
        firmwareUpdateSuccess   = 0x2,
        connParamUpdateFailed   = 0x3,
        connParamUpdateSuccess  = 0x4,
        authSuccess             = 0x5,
        authFailed              = 0x6,
        fitnessGoalAchieved     = 0x7,
        setLatencySuccess       = 0x8,
        resetAuthFailed         = 0x9,
        resetAuthSuccess        = 0x10,
        firmwareCheckFailed     = 0x11,
        firmwareCheckSuccess    = 0x12,
        motorNotify             = 0x13,
        motorCall               = 0x14,
        motorDisconnect         = 0x15,
        motorSmartAlarm         = 0x16,
        motorAlarm              = 0x17,
        motorGoal               = 0x18,
        motorAuth               = 0x19,
        motorShutdown           = 0x20,
        motorAuthSuccess        = 0x21,
        motorTest               = 0x22,
        // I remember I got 0x18 !? while keeping shaking mi band at starting the app
        pairCancel              = 0xef,
        deviceMalfunction       = 0xff
    }
    
    enum FUActivityType: Int8 {
        case
        activity    = -1,
        nonWear     = 3,
        deepSleep   = 4,
        lightSleep  = 5,
        charging    = 6
    }
    
    enum FUBatteryStatus: UInt8 {
        case
        normal          = 0,
        low             = 1,
        charging        = 2,
        chargingFull    = 3,
        chargeOff       = 4
    }
    
    /* References ..... somewhat contradicted to each other. My implementation is based on android on
     typedef NS_OPTIONS(NSInteger, MBControlPoint) {
     MBControlPointStopCallRemind = 0,
     MBControlPointCallRemind,
     MBControlPointRealtimeSetpsNotification = 3,
     MBControlPointTimer,
     MBControlPointGoal,
     MBControlPointFetchData,
     MBControlPointFirmwareInfo,
     MBControlPointSendNotification,
     MBControlPointReset,
     MBControlPointConfirmData,
     MBControlPointSync,
     MBControlPointReboot = 12,
     MBControlPointColor = 14,
     MBControlPointWearPosition,
     MBControlPointRealtimeSteps,
     MBControlPointStopSync,
     MBControlPointSensorData,
     MBControlPointStopVibrate
     };
     
     /* COMMANDS: usually sent to UUID_CHARACTERISTIC_CONTROL_POINT characteristic */
     
     public static final byte COMMAND_SET_TIMER = 0x4;
     public static final byte COMMAND_SET_FITNESS_GOAL = 0x5;
     public static final byte COMMAND_FETCH_DATA = 0x6;
     public static final byte COMMAND_SEND_FIRMWARE_INFO = 0x7;
     public static final byte COMMAND_SEND_NOTIFICATION = 0x8;
     public static final byte COMMAND_CONFIRM_ACTIVITY_DATA_TRANSFER_COMPLETE = 0xa;
     public static final byte COMMAND_SYNC = 0xb;
     public static final byte COMMAND_REBOOT = 0xc;
     public static final byte COMMAND_SET_WEAR_LOCATION = 0xf;
     public static final byte COMMAND_STOP_SYNC_DATA = 0x11;
     public static final byte COMMAND_STOP_MOTOR_VIBRATE = 0x13;
     public static final byte COMMAND_SET_REALTIME_STEPS_NOTIFICATION = 0x3;
     public static final byte COMMAND_SET_REALTIME_STEP = 0x10;
     
     // Test HR
     public static final byte COMMAND_SET_HR_SLEEP = 0x0;
     public static final byte COMMAND_SET__HR_CONTINUOUS = 0x1;
     public static final byte COMMAND_SET_HR_MANUAL = 0x2;
     public static final byte COMMAND_GET_SENSOR_DATA = 0x12;
     
     
     //FURTHER COMMANDS: unchecked therefore left commented
     public static final byte COMMAND_FACTORY_RESET = 0x9t;
     public static final int COMMAND_SET_COLOR_THEME = et;
     
     */
    
    enum ControlPointCommand: UInt8 {
        case
        setHeartRateSleep                   = 0x0,
        setHeartRateContinuous              = 0x1,
        setHeartRateManual                  = 0x2,
        setRealtimeStepNotification         = 0x3,
        setTimer                            = 0x4,
        setFitnessGoal                      = 0x5,
        fetchData                           = 0x6,
        firmwareInfo                        = 0x7,
        sendNotification                    = 0x8,
        factoryReset                        = 0x9,
        confirmActivityDataTransferComplete = 0xa,
        sync                                = 0xb,
        reboot                              = 0xc,
        setColorTheme                       = 0xe,
        setWearPosition                     = 0xf,
        setRealtimeStep                     = 0x10,
        stopSyncData                        = 0x11,
        getSensorData                       = 0x12,
        stopMotorVibrate                    = 0x13
    }
}
