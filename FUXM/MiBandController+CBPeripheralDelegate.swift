//
//  MiBandController+CBPeripheralDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import CoreBluetooth.CBPeripheral

extension MiBandController: CBPeripheralDelegate {
    // MARK - CBPeripheralDelegate - Discovering services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) error: \(error)")
        guard nil == error else {
            // TODO fail callback
            return
        }
        guard let services = peripheral.services else {
            debugPrint("No service discovered. Abort.")
            // success callbakc
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(Consts.characteristics, for: service)
            peripheral.discoverIncludedServices(nil, for: service)  // TEST: Got something for this. Dig deeper
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) service: \(service) error: \(error)")
        peripheral.discoverCharacteristics(Consts.characteristics, for: service)
    }
    
    // MARK - CBPeripheralDelegate - Discovering characteristics and characteristics descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) service: \(service) error: \(error)")
        guard nil == error else {
            // TODO fail callback
            return
        }
        guard let characteristics = service.characteristics else {
            debugPrint("No characteristics discovered for service \(service.uuid). Abort.")
            // success callback
            return
        }
        
        debugPrint("characterstics: \(characteristics)")
        for characteristic in characteristics {
            characteristicsAvailable[FUCharacteristicUUID(rawValue: UInt16(characteristic.uuid.uuidString, radix: GlobalConsts.hexRadix)!)!] = characteristic    // TODO: crash due to receiving characteristic of UUID FED0
        }
        
        // TODO: refactor..... 
        let gotAllCharacteristics = peripheral.services?.reduce(true, { (result, service) -> Bool in
            return result && (service.characteristics != nil)
        })
        if let ready = gotAllCharacteristics, true == ready {
//            MiBandUserDefaults.storeBoundPeripheralUUID(peripheral.identifier)
//            boundPeripheral = peripheral
            setupPeripheral(peripheral)
        }
    }
    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
//        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error)")
//    }
    
    // MARK - CBPeripheralDelegate - Retrieving characteristic and characteristic descriptor values
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error) value: \(characteristic.value)")
//        guard nil == error else {
//            debugPrint("Error occurred: \(error)")
//            return
//        }
//        if characteristic.isNotifying {
//            // TODO: handle notified value
//        }
        
        guard let converted = UInt16(characteristic.uuid.uuidString, radix:GlobalConsts.hexRadix),
            let uuid = FUCharacteristicUUID(rawValue: converted) else {
            debugPrint("Cannot convert incoming uuid \(characteristic.uuid). Abort")
            return
        }
        switch uuid {
        case .alertLevel:
            // TODO
            break
        case .deviceInfo:
            // TODO
            self.delegate?.onUpdateDeviceInfo?(deviceInfo: FUDeviceInfo(data: characteristic.value), isNotifiying: characteristic.isNotifying, error: error)
            break
        case .deviceName:
            // TODO
            break
        case .notification:
            // TODO
            break
        case .userInfo:
            // TODO
            break
        case .controlPoint:
            // TODO
            break
        case .realtimeSteps:
            // TODO
            break
        case .activityData:
            // TODO
            break
        case .firmwareData:
            // TODO
            break
        case .leParams:
            // TODO
            break
        case .dateTime:
            // TODO
            break
        case .statistics:
            // TODO
            break
        case .battery:
//            handleBatteryInfo(value: characteristic.value)
            // TODO
            break
        case .test:
            // TODO
            break
        case .sensorData:
            // TODO
//            handleSensorData(value: characteristic.value)
            break
        case .pair:
            // TODO
            break
        case .unknown1, .unknown2, .unknown3, .unknown4, .unknown5,
             .unknown6, .unknown7, .unknown8, .unknown9, .unknown10, .weird:
            debugPrint("unknown characteristics. value \(characteristic.value)")
            break
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) descriptor: \(descriptor) error: \(error)")
        // TODO: update value delegate or callback
    }
    
    // MARK - CBPeripheralDelegate - Writing characteristic and characteristic descriptor values
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error)")
        // TODO: maybe did write call back?
    }
    
//    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
//        debugPrint("\(#function) peripheral: \(peripheral) descriptor: \(descriptor) error: \(error)")
//        
//    }
    
    // MARK - CBPeripheralDelegate - Managing notifications for a characteristic's value
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error)")
//        handleNotifications(from: characteristic)
        // TODO: notif handler or notif callback?
    }
    
    // MARK - CBPeripheralDelegate - Retrieving a Peripheral’s Received Signal Strength Indicator (RSSI) Data
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) RSSI: \(RSSI) error: \(error)")
    }
    
    // MARK - CBPeripheralDelegate - Monitoring Changes to a Peripheral’s Name or Services
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        debugPrint("\(#function) peripheral: \(peripheral)")
        // TODO: maybe delegate method or callback?
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        debugPrint("\(#function) peripheral: \(peripheral) invalidatedServices: \(invalidatedServices)")
        // TODO: maybe delegate method or callback?
    }
    
    // MARK - private methods
    private func setupPeripheral(_ peripheral: CBPeripheral) {
//        assert(nil != self.boundPeripheral, "self.boundPeripheral == nil")
  
        self.activePeripheral = peripheral
        readDeviceInfo()
        
/*
        boundPeripheral.setNotifyValue(true, for: characteristicsAvailable[.notification]!)
        let lowLatencyData = createLatency(minConnInterval: 39, maxConnInterval: 49, latency: 0, timeout: 500, advertisementInterval: 0)
        boundPeripheral.writeValue(lowLatencyData, for: characteristicsAvailable[CharacteristicUUID.leParams]!, type: .withResponse)
        boundPeripheral.readValue(for: characteristicsAvailable[CharacteristicUUID.dateTime]!)
        boundPeripheral.writeValue(Data(bytes:[0x2]), for: characteristicsAvailable[CharacteristicUUID.pair]!, type: .withResponse)
        boundPeripheral.readValue(for: characteristicsAvailable[CharacteristicUUID.deviceInfo]!)
        let userInfo = createUserInfo(uid: test, gender: 1, age: 36, height: 170, weight: 64, type: 1, alias: "Luis")
//        let userInfo = Data(bytes: [0x73, 0xdc, 0x32, 0x0, 0x2, 0x19, 0xaf, 0x46, 0x0, 0x6c, 0x75, 0x69, 0x73, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x25]) // HERE! the user info format
        boundPeripheral.writeValue(userInfo, for: characteristicsAvailable[CharacteristicUUID.userInfo]!, type: .withResponse)
        
        boundPeripheral.readValue(for: characteristicsAvailable[.userInfo]!)
        
        // check authentication needed
        
        boundPeripheral.writeValue(Data(bytes:[ControlPointCommand.setWearPosition.rawValue, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
        
        // setHeartrateSleepSupport (may not apply)
        
        boundPeripheral.writeValue(Data(bytes:[ControlPointCommand.setFitnessGoal.rawValue, 0x0, UInt8(truncatingBitPattern: 10000), UInt8(truncatingBitPattern: 10000 >> 8)]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
        
        boundPeripheral.setNotifyValue(true, for: characteristicsAvailable[.realtimeSteps]!)
        boundPeripheral.setNotifyValue(true, for: characteristicsAvailable[.activityData]!)
        boundPeripheral.setNotifyValue(true, for: characteristicsAvailable[.battery]!)
        boundPeripheral.setNotifyValue(true, for: characteristicsAvailable[.sensorData]!)
        
        let nowData = createDate(newerDate: Date())
        boundPeripheral.writeValue(nowData, for: characteristicsAvailable[.dateTime]!, type: .withResponse)
        boundPeripheral.readValue(for: characteristicsAvailable[.battery]!)
        let highLatencyData = createLatency(minConnInterval: 460, maxConnInterval: 500, latency: 0, timeout: 500, advertisementInterval: 0)
        boundPeripheral?.writeValue(highLatencyData, for: characteristicsAvailable[CharacteristicUUID.leParams]!, type: .withResponse)
        
        // TODO : set initialized
        */
        
        
        
        /*
        
//        boundPeripheral?.readValue(for: characteristicsAvailable[CharacteristicUUID.userInfo]!)
        // TEST
        
//        boundPeripheral?.writeValue(Data(bytes:[ControlPointCommand.sendNotification.rawValue, 1]), for: characteristicsAvailable[CharacteristicUUID.controlPoint]!, type: .withoutResponse)
//        boundPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setLEDColor.rawValue, 6, 0, 6, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
//        boundPeripheral?.writeValue(Data(bytes:[0x1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
        
        boundPeripheral.writeValue(Data(bytes:[0x12, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
        
        boundPeripheral.readValue(for: characteristicsAvailable[.sensorData]!)
        
        
//        boundPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setLEDColor.rawValue, 0, 0, 6, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
    */
    }
}
