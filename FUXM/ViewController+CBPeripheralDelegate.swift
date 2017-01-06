 //
//  ViewController+CGPeripheralDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 12/15/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import CoreBluetooth

extension UInt32: DataConvertible {
    init(data:Data) {
        guard data.count == MemoryLayout<UInt32>.size else {
            fatalError("data size (\(data.count)) != type size (\(MemoryLayout<UInt32>.size))")
        }
        self = data.withUnsafeBytes { $0.pointee }
    }
    
    var data:Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

// END TEST

extension ViewController: CBPeripheralDelegate {

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("\(#function), pepripheral: \(peripheral)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("\(#function), peripheral: \(peripheral), invalidatedServices: \(invalidatedServices)")
    }
    
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        print("\(#function), error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("\(#function), RSSI: \(RSSI) error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\(#function), error: \(error)")
        
        if let services = peripheral.services {
            for service in services {
                print("service of \(peripheral.name) : \(service) ")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("\(#function), service: \(service), error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("\(#function), service: \(service), error: \(error)")
        
        // TEST
//        if service.uuid == CBUUID(string: "1802") {
//            service.characteristics?.forEach({ (characteristic) in
//                print("characteristic \(characteristic)")
//                let data = Data(UInt8s: [8])  // 0 no alert, 1 mild alert, 2 high alert , 4 ：vibrate only
//                
//                peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
//            })
////            for characteristic in service.characteristics {
////                print(characteristic)
////            }
//        }
        
        
        if service.uuid == CBUUID(string: "FEE0") {
            service.characteristics?.forEach({ (characteristic) in
                print("characteristic \(characteristic.uuid)")
                if (characteristic.uuid.uuidString.caseInsensitiveCompare("FF0F") == .orderedSame) {
                    let data = Data(bytes: [0 , 0])
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                }
                
                if (characteristic.uuid.uuidString.caseInsensitiveCompare("FF05") == .orderedSame) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    let data = Data(bytes: [0x8, 0x2])
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                }
            })
        }
        
        // END TEST
        
        print("Discovered characteristics for service \(service.uuid)")
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("characteristic of \(service.uuid): \(characteristic.uuid)")
                
//                switch characteristic.uuid.uuidString {
//                case XiaoMiCharacteristics.deviceInfo.rawValue:
//                    print("deviceInfo")
//                    break
//                case XiaoMiCharacteristics.deviceName.rawValue:
//                    print("deviceName")
//                    
//                    break
//                case XiaoMiCharacteristics.notification.rawValue:
//                    print("notification")
//                    break
//                case XiaoMiCharacteristics.userInfo.rawValue:
//                    print("userInfo")
//                    break
//                case XiaoMiCharacteristics.controlPoint1.rawValue:
//                    print("controlPoint1")
//                    break
//                case XiaoMiCharacteristics.steps.rawValue:
//                    print("steps")
//                    peripheral.readValue(for: characteristic)
//                    break
//                case XiaoMiCharacteristics.activityData.rawValue:
//                    print("activityData")
//                    break
//                case XiaoMiCharacteristics.firmwareData.rawValue:
//                    print("firmwareData")
//                    break
//                case XiaoMiCharacteristics.leParams.rawValue:
//                    print("leParams")
//                    break
//                case XiaoMiCharacteristics.dateTime.rawValue:
//                    print("dateTime")
//                    break
//                case XiaoMiCharacteristics.statistics.rawValue:
//                    print("statistics")
//                    break
//                case XiaoMiCharacteristics.battery.rawValue:
//                    print("battery")
//                    break
//                case XiaoMiCharacteristics.test.rawValue:
//                    print("test")
//                    break
//                case XiaoMiCharacteristics.sensorData.rawValue:
//                    print("sensorData")
//                    break
//                case XiaoMiCharacteristics.pair.rawValue:
//                    print("pair")
//                    break
//                case XiaoMiCharacteristics.controlPoint2.rawValue:
//                    print("controlPoint2")
//                    break
//                case XiaoMiCharacteristics.measurement.rawValue:
//                    print("measurement")
//                    break
//                case XiaoMiCharacteristics.feature.rawValue:
//                    print("feature")
//                    break
//                default:
//                    print("unknown")
//                    break
//                }
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#function), error: \(error)")
        
        // determine characteristic properties
        print("characteristic properties : \(characteristic.properties)")
        if characteristic.properties.contains(.broadcast) {
            print("broadcast")
        }
        if characteristic.properties.contains(.read) {
            print("read")
        }
        if characteristic.properties.contains(.writeWithoutResponse) {
            print("write without response")
        }
        if characteristic.properties.contains(.write) {
            print("write")
        }
        if characteristic.properties.contains(.notify) {
            print("notify")
        }
        if characteristic.properties.contains(.indicate) {
            print("indicate")
        }
        if characteristic.properties.contains(.authenticatedSignedWrites) {
            print("authenticated signed writes")
        }
        if characteristic.properties.contains(.extendedProperties) {
            print("extended properties")
        }
        if characteristic.properties.contains(.notifyEncryptionRequired) {
            print("notify encryption required")
        }
        if characteristic.properties.contains(.indicateEncryptionRequired) {
            print("indicate encryption required")
        }
        
        print("characteristic descriptors : \(characteristic.descriptors)")
        
        
        
        switch characteristic.uuid.uuidString {
        case XiaoMiCharacteristics.deviceInfo.rawValue:
            // read
            // TODO: https://github.com/pigigaldi/MiBand-Utility/blob/f0be6f6838e1ee2b7c21ea794dd680130dfd251d/mibandutility/MiBand/MBPeripheral.h
                // size : characteristic.value?.count
                var uuid: [UInt8] = Array<UInt8>(repeatElement(0, count: characteristic.value!.count))
                characteristic.value!.copyBytes(to: &uuid, count: characteristic.value!.count)
                var deviceId = ""
                for UInt8 in uuid[0...7] {
                    deviceId.append(String(format: "%02x", UInt8))
                }
                print("deviceId: \(deviceId)")
                
                // UInt8 11, 10, 9, 8 (profile version x.x.x.x)
                var profileVersion = ""
                for UInt8 in uuid[8...11].reversed() {
                    profileVersion.append(String(format: UInt8 == uuid[8...11].reversed().last ? "%d" : "%d." , UInt8))
                }
                print("profileVersion: \(profileVersion)")
                
                // UInt8 15, 14, 13, 12 (firmawre version x.x.x.x)
                var firmwareVersion = ""
                for UInt8 in uuid[12...15].reversed() {
                    firmwareVersion.append(String(format: UInt8 == uuid[12...15].reversed().last ? "%d" : "%d." , UInt8))
                    
                }
                print("firmwareVersion: \(firmwareVersion)")
                
                
                let feature = Int(uuid[4])
                let appearence = Int(uuid[5])
                let hardwareVersion = Int(uuid[6]) //???
                print("feature:\(feature), appearance:\(appearence), hardwareversion:\(hardwareVersion)")
                
            // read
//                print("deviceInfo: \(NSUUID(uuidUInt8s: uuid).uuidString)")
            break
        case XiaoMiCharacteristics.deviceName.rawValue:
            // read, write
            if let value = characteristic.value {
                print("deviceName: \(String(data: value, encoding: .utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))")
            }
            break
        case XiaoMiCharacteristics.notification.rawValue:
            // read, notify
            print("notification")
            break
        case XiaoMiCharacteristics.userInfo.rawValue:
            
            
            print("userInfo")
            // read , write
//            guard let data = characteristic.value else { return }
//            guard data.count == MemoryLayout<UInt32>.size else {
//                fatalError("data size (\(data.count)) != type size (\(MemoryLayout<UInt32>.size))")
//            }
//            self = data.withUnsafeUInt8s { $0.pointee }
            break
        case XiaoMiCharacteristics.controlPoint1.rawValue:
            print("controlPoint1.\(peripheral.maximumWriteValueLength(for: .withResponse)) ")
            
            break
        case XiaoMiCharacteristics.steps.rawValue:
            // read, notify
            print("steps")
            guard let data = characteristic.value else { return }
            print("counter is \(UInt32(data: data))")
            break
        case XiaoMiCharacteristics.activityData.rawValue:
            // read, notify
            print("activityData")
            break
        case XiaoMiCharacteristics.firmwareData.rawValue:
            print("firmwareData")
            break
        case XiaoMiCharacteristics.leParams.rawValue:
            // TODO https://github.com/betomaluje/Mi-Band/blob/master/MiBand/app/src/main/java/com/betomaluje/miband/model/LeParams.java
            print("leParams")
            break
        case XiaoMiCharacteristics.dateTime.rawValue:
            // read, write
//            let calendar = Calendar(identifier: .gregorian)
//            let dateComponents = NSDateComponents()
//            dateComponents.calendar = calendar
//            dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
// 
// 
//            var uuid: [UInt8] = Array<UInt8>(repeatElement(0, count: characteristic.value!.count))
//            characteristic.value!.copyUInt8s(to: &uuid, count: characteristic.value!.count)
 
            /*
            NSDateComponents *dataComponents = [[NSDateComponents alloc] init];
            dataComponents.calendar = calendar;
            dataComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            dataComponents.year = _UInt8s[_pos++] + 2000;
            dataComponents.month = _UInt8s[_pos++] + 1;
            dataComponents.day = _UInt8s[_pos++];
            dataComponents.hour = _UInt8s[_pos++];
            dataComponents.minute = _UInt8s[_pos++];
            dataComponents.second = _UInt8s[_pos++];
            return [dataComponents date];*/
  
            
            
            ///////// write
            
            let currentDate = Date()
            let calendar = Calendar(identifier: .gregorian)
            let calendarComponents: Set<Calendar.Component> = [ .year , .month, .day, .hour, .minute, .second]
            let dateComponents = calendar.dateComponents(calendarComponents, from: currentDate)
            let dataToWrite: Data = Data(bytes: [UInt8(dateComponents.year! - 2000),
                                      UInt8(dateComponents.month! - 1),
                                      UInt8(dateComponents.day!),
                                      UInt8(dateComponents.hour! + 1),
                                      UInt8(dateComponents.minute!),
                                      UInt8(dateComponents.second!),
                                      
                                      
                                      UInt8(dateComponents.year! - 2000),
                                      UInt8(dateComponents.month! - 1),
                                      UInt8(dateComponents.day!),
                                      UInt8(dateComponents.hour!),
                                      UInt8(dateComponents.minute!),
                                      UInt8(dateComponents.second!),
            ])
            
            peripheral.writeValue(dataToWrite, for: characteristic, type: .withResponse)
            
            
            
            /*
  
  - (instancetype)writeDate:(NSDate *)value {
  if (value) {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:value];
  [self writeInt:(components.year - 2000) UInt8sCount:1];
  [self writeInt:(components.month - 1) UInt8sCount:1];
  [self writeInt:components.day UInt8sCount:1];
  [self writeInt:components.hour UInt8sCount:1];
  [self writeInt:components.minute UInt8sCount:1];
  [self writeInt:components.second UInt8sCount:1];
  } else {
  for (NSUInteger i = 0; i < 6; i++) {
  [self writeInt:0xff UInt8sCount:1];
  }
  }
  return self;
  }*/
  
  
            print("dateTime")
  
  
            break
        case XiaoMiCharacteristics.statistics.rawValue:
            // read, write
            print("statistics")
            break
        case XiaoMiCharacteristics.battery.rawValue:
            // read, notify 10UInt8s
            print("battery")
            break
        case XiaoMiCharacteristics.test.rawValue:
            // read, write 4 UInt8s
            print("test")
            break
        case XiaoMiCharacteristics.sensorData.rawValue:
            // r, w, notify
            print("sensorData")
            break
        case XiaoMiCharacteristics.pair.rawValue:
            // read, write 2 UInt8s
            print("pair")
            break
        case XiaoMiCharacteristics.controlPoint2.rawValue:
            print("controlPoint2")
            break
        case XiaoMiCharacteristics.measurement.rawValue:
            print("measurement")
            break
        case XiaoMiCharacteristics.feature.rawValue:
            print("feature")
            break
        default:
            print("unknown")
            
            // UUID FEDD : write
            // FEDE : read
            // FEDF: read
            // FED0: write
            // FED1: write
            
            break
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#function), characteristic:\(characteristic), error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#function), characteristic:\(characteristic), error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#function), characteristic:\(characteristic), error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("\(#function), descriptor:\(descriptor), error: \(error)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("\(#function), descriptor:\(descriptor), error: \(error)")
    }
    
}
