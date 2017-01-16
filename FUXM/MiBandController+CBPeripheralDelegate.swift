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
            if let uuid = FUCharacteristicUUID(rawValue: UInt16(characteristic.uuid.uuidString, radix: GlobalConsts.hexRadix)!) {
                characteristicsAvailable[uuid] = characteristic    // TODO: crash due to receiving characteristic of UUID FED0 1, 2, 3 (mi band 2)
            } else {
                debugPrint("DEBUG - got characteristic with uuid: \(characteristic.uuid.uuidString)")
            }
        }
        
        // TODO: refactor.....
        let gotAllCharacteristics = peripheral.services?.reduce(true, { (result, service) -> Bool in
            return result && (service.characteristics != nil)
        })
        if let ready = gotAllCharacteristics, true == ready {
            //            MiBandUserDefaults.storeBoundPeripheralUUID(peripheral.identifier)
            //            boundPeripheral = peripheral
            setupPeripheral(peripheral)
            // TEST
            printPropertiesFor(characteristicsAvailable)
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
        
        debugPrint("uuid gotten: \(uuid)")
        
        switch uuid {
        case .alertLevel:
            // TODO
            break
        case .deviceInfo:
            // TODO
            debugPrint("DEBUG - HERE")
            self.delegate?.onUpdateDeviceInfo?(FUDeviceInfo(data: characteristic.value), isNotifying: characteristic.isNotifying, error: error)
            
            // TEST  ---- TRY HERE
            
            //            self.setNotify(enable: true, characteristic: .sensorData)
            //            self.startSensorData()
            
            //            self.readSensorData()
            
            // good combination!
            //            self.setNotify(enable: true, characteristic: .notification)
            //            self.setNotify(enable: true, characteristic: .activityData)
            
            //            self.reboot()
            
            
            //            self.setNotify(enable: true, characteristic: .sensorData)
            
            //            self.writeLEParams(FULEParams.lowLatencyLEParams())
            //            self.readLEParams()
            //            self.writeDateTime(Date())  // write won't didUpdate datetime
            //            self.readDateTime()
            //            self.readUserInfo()
            // END TEST
            break
        case .deviceName:
            // TODO
            break
        case .notification:
            // TODO
            break
        case .userInfo:
            // TODO
            self.delegate?.onUpdateUserInfo?(FUUserInfo(data: characteristic.value), error: error)
            break
        case .controlPoint:
            // TODO
            break
        case .realtimeSteps:
            // TODO
            let steps: UInt16 = characteristic.value!.withUnsafeBytes { return ($0 as UnsafePointer<[UInt8]>).withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee } ) }
            self.delegate?.onUpdateRealtimeSteps?(steps, isNotifying: characteristic.isNotifying, error: error)
            break
        case .activityData:
            // TODO
            break
        case .firmwareData:
            // TODO
            break
        case .leParams:
            self.delegate?.onUpdateLEParams?(FULEParams(data: characteristic.value), isNotifying: characteristic.isNotifying, error: error)
            break
        case .dateTime:
            self.delegate?.onUpdateDateTime?(FUDateTime(data: characteristic.value), error: error)
            break
        case .statistics:
            // TODO
            break
        case .battery:
            //            handleBatteryInfo(value: characteristic.value)
            self.delegate?.onUpdateBatteryInfo?(FUBatteryInfo(data: characteristic.value), isNotifying: characteristic.isNotifying, error: error)
            // TODO
            break
        case .test:
            // TODO
            break
        case .sensorData:
            // TODO
            self.delegate?.onUpdateSensorData?(FUSensorData(data: characteristic.value), isNotifying: characteristic.isNotifying, error: error)
            //            handleSensorData(value: characteristic.value)
            break
        case .pair:
            // TODO
            break
        case .unknown1, .unknown2, .unknown3, .unknown4, .unknown5,
             .unknown6, .unknown7, .unknown8, .unknown9, .unknown10,
             .unknown11, .unknown12,
             .weird:
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
        
        guard let converted = UInt16(characteristic.uuid.uuidString, radix:GlobalConsts.hexRadix),
            let uuid = FUCharacteristicUUID(rawValue: converted) else {
                debugPrint("Cannot convert incoming uuid \(characteristic.uuid). Abort")
                return
        }
        
        debugPrint("uuid gotten: \(uuid)")
        
        switch uuid {
        case .notification:
            // TODO
            break
        case .realtimeSteps:
            let steps: UInt16 = characteristic.value!.withUnsafeBytes { return ($0 as UnsafePointer<[UInt8]>).withMemoryRebound(to: UInt16.self, capacity: MemoryLayout<UInt16>.size, { return $0.pointee } ) }
            self.delegate?.onUpdateRealtimeSteps?(steps, isNotifying: characteristic.isNotifying, error: error)
        case .activityData:
            guard nil == error else {
                self.delegate?.onUpdateActivityData?(nil, isNotifying: characteristic.isNotifying, error: error)
                return
            }
//            assert(self.activityDataReader != nil, "Unexpected activityDataReader == nil")    
            guard let value = characteristic.value else {
                debugPrint("Got empty value. Skipped")
                return
            }
            self.activityDataReader?.append(data: value)
            if self.activityDataReader?.state == .done {
                self.delegate?.onUpdateActivityData?(activityDataReader?.activityFragments, isNotifying: characteristic.isNotifying, error: error)
//                self.activityDataReader = nil
            }
            break
        case .battery:
            // TODO
            break
        case .sensorData:
            // TODO
            break
        default:
            debugPrint("uuid: \(uuid). Simply ignore.")
            break
        }
        
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
        setNotify(enable: true, characteristic: .notification)
        writeLEParams(FULEParams.lowLatencyLEParams())
        bindPeripheral(self.activePeripheral!)
        writeUserInfo(FUUserInfo(uid: 123, gender: .male, age: 36, height: 170, weight: 62, type: .normal, alias: "LUIS"), salt:0x3E)    // TEST
        boundPeripheral = self.activePeripheral!
        setWearPosition(position: .leftHand)
        setFitnessGoal(steps: 10000)
        
//        setNotify(enable: true, characteristic: .realtimeSteps)       // crash
        setNotify(enable: true, characteristic: .activityData)
        fetchData()
        setNotify(enable: true, characteristic: .battery)
//        setNotify(enable: true, characteristic: .sensorData)
        writeDateTime(Date())
        readDateTime()
//        writeLEParams(FULEParams.highLatencyLEParams())
    }
    
    private func printPropertiesFor(_ characteristicDict: [FUCharacteristicUUID : CBCharacteristic]) {
        for key in characteristicDict.keys {
            let characteristic = characteristicDict[key]!
            print("Characteristic: \(key) - properties: [ " , terminator:"")
            
            // determine characteristic properties
            if characteristic.properties.contains(.broadcast) {
                print("broadcast ", terminator: "")
            }
            if characteristic.properties.contains(.read) {
                print("read ", terminator: "")
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                print("write-without-response ", terminator: "")
            }
            if characteristic.properties.contains(.write) {
                print("write ", terminator: "")
            }
            if characteristic.properties.contains(.notify) {
                print("notify ", terminator: "")
            }
            if characteristic.properties.contains(.indicate) {
                print("indicate ", terminator: "")
            }
            if characteristic.properties.contains(.authenticatedSignedWrites) {
                print("authenticated-signed-writes ", terminator: "")
            }
            if characteristic.properties.contains(.extendedProperties) {
                print("extended-properties ", terminator: "")
            }
            if characteristic.properties.contains(.notifyEncryptionRequired) {
                print("notify-encryption-required ", terminator: "")
            }
            if characteristic.properties.contains(.indicateEncryptionRequired) {
                print("indicate-encryption-required ", terminator: "")
            }
            print("]" )   // end of line
        }
    }
}
