//
//  ViewController.swift
//  FUXM
//
//  Created by Luis Wu on 12/7/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var stopScanBtn: UIButton!
    @IBOutlet var vibrateBtn: UIButton!
    
    // MARK - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        enableButtons()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - IBActions
    @IBAction func scan(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
//        guard !cbCentralManager.isScanning else { return }
//        scanMiBands()
    }
    
    @IBAction func stopScan(sender: UIButton) { // manually stop scanning
        debugPrint("\(#function) sender: \(sender)")
//        cbCentralManager.stopScan()
    }
    
    @IBAction func vibrate(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
//        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setLEDColor.rawValue, 6, 0, 6, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
//        pairingPeripheral?.writeValue(Data(bytes:[1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)   // workable!
    }
    

    
    
    
    // MARK - private methods
    func enableButtons() {
        scanBtn.isEnabled = true
        stopScanBtn.isEnabled = true
        vibrateBtn.isEnabled = true
    }
    
    func disableButtons() {
        scanBtn.isEnabled = false
        stopScanBtn.isEnabled = false
        vibrateBtn.isEnabled = false
    }
    
    /*
    func scanMiBands() {
        discoveredPeripherals.removeAll()   // clear discovered peripherals
        cbCentralManager.scanForPeripherals(withServices: Consts.miBandServiceUUIDs, options: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(Consts.scanDuration)) { [unowned self] in
            var alert: UIAlertController? = nil
            if self.discoveredPeripherals.count > 0 {
                alert = UIAlertController(title: "Devices found", message: "Choose the device to pair with", preferredStyle: .actionSheet)
                for peripheral in self.discoveredPeripherals {
                    if let name = peripheral.name {
                        alert!.addAction(
                            UIAlertAction(title: name,
                                          style: .default,
                                          handler: { [unowned self] (action) in
                                            self.cbCentralManager.connect(peripheral, options: Consts.peripheralConnOptions)
                            }))
                    }
                }
                alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    print("\(action.title)")
                }))
            } else {
                alert = UIAlertController(title: "Devices not found", message: "Devices not foud", preferredStyle: .actionSheet)
                alert!.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            }
            if let alert = alert {
                self.present(alert, animated: true, completion: nil)
            }
            self.stopScan(sender: self.stopScanBtn)
        }
    }
    
    
    
    
    
    func createLatency(minConnInterval: Int, maxConnInterval: Int, latency: Int, timeout: Int, advertisementInterval: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: 12)
        bytes[0] = UInt8(truncatingBitPattern: minConnInterval)
        bytes[1] = UInt8(truncatingBitPattern: minConnInterval >> 8)
        bytes[2] = UInt8(truncatingBitPattern: maxConnInterval)
        bytes[3] = UInt8(truncatingBitPattern: maxConnInterval >> 8)
        bytes[4] = UInt8(truncatingBitPattern: latency)
        bytes[5] = UInt8(truncatingBitPattern: latency >> 8)
        bytes[6] = UInt8(truncatingBitPattern: timeout)
        bytes[7] = UInt8(truncatingBitPattern: timeout >> 8)
        bytes[8] = 0
        bytes[9] = 0
        bytes[10] = UInt8(truncatingBitPattern: advertisementInterval)
        bytes[11] = UInt8(truncatingBitPattern: advertisementInterval >> 8)
        return Data(bytes: bytes)
    }
    
    func createUserInfo(uid: Int32, gender: Int, age: Int, height: Int, weight: Int, type: Int, alias: String) -> Data {
        var bytes: [UInt8] = []
        bytes.append(UInt8(truncatingBitPattern: uid.bigEndian))
        bytes.append(UInt8(truncatingBitPattern: uid.bigEndian >> 8))
        bytes.append(UInt8(truncatingBitPattern: uid.bigEndian >> 16))
        bytes.append(UInt8(truncatingBitPattern: uid.bigEndian >> 24))
        bytes.append(UInt8(truncatingBitPattern: gender))
        bytes.append(UInt8(truncatingBitPattern: age))
        bytes.append(UInt8(truncatingBitPattern: height))
        bytes.append(UInt8(truncatingBitPattern: weight))
        bytes.append(UInt8(truncatingBitPattern: type))
        bytes.append(contentsOf:Array(alias.utf8))
        let paddingCount = 19 - bytes.count
        if  paddingCount > 0  {
            bytes.append(contentsOf: Array<UInt8>(repeating:UInt8(0), count:paddingCount))
        }
        bytes.append(checksum(bytes: bytes, from: 0, length: 19, lastMACByte:0x3E))  // 3E may from deviceInfo's last byte!
        // TODO not mili 1
        return Data(bytes: bytes)
    }
    
    
    func checksum(bytes: [UInt8],from index: Int, length: Int, lastMACByte: UInt8) -> UInt8 {
        let input = Array<UInt8>(bytes[index ..< bytes.count])
        let crc = crc8WithBytes(bytes: input, length: length)
        return crc ^ 0xff & lastMACByte
    }
    
    func crc8WithBytes(bytes: [UInt8], length: Int) -> UInt8 {
        var checksum: UInt8 = 0
        for i in 0 ..< length {
         checksum ^= bytes[i]
            for _ in 0 ..< 8 {
                if (checksum & 0x1 as UInt8) > 0 {
                    checksum = (0x8c ^ (0xff & checksum >> 1))
                } else {
                    checksum = (0xff & checksum >> 1)
                }
            }
        }
        return checksum
    }
    
    func createDate(newerDate: Date, olderDate: Date? = nil) -> Data {
        var bytes: [UInt8] = []
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: newerDate)
        bytes.append(UInt8(truncatingBitPattern: dateComponents.year! - 2000))
        bytes.append(UInt8(truncatingBitPattern: dateComponents.month! - 1))
        bytes.append(UInt8(truncatingBitPattern: dateComponents.day!))
        bytes.append(UInt8(truncatingBitPattern: dateComponents.hour!))
        bytes.append(UInt8(truncatingBitPattern: dateComponents.minute!))
        bytes.append(UInt8(truncatingBitPattern: dateComponents.second!))
        return Data(bytes:bytes)
    }
    
    
    func handleNotifications(from characteristic: CBCharacteristic) {
        debugPrint("\(#function) characteristic: \(characteristic)")
        if let value = characteristic.value {
            
            if characteristic.uuid.uuidString.compare("FF0E") == .orderedSame {
               debugPrint("characteristic.value = \(value)")
            }
            
            guard value.count > 0 else {
                debugPrint("value.count == 0. do nothing")
                return
            }
            
            let notification = Notifications(rawValue: value.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt8 in
                return pointer.pointee
            }))
            
            guard notification != nil else { return }
            
            switch notification! {
            case .normal:
                break
            case .firmwareUpdateFailed:
                break
            case .firmwareUpdateSuccess:
                break
            case .connParamUpdateFailed:
                break
            case .connParamUpdateSuccess:
                break
            case .authSuccess:
                break
            case .authFailed:
                break
            case .fitnessGoalAchieved:
                break
            case .setLatencySuccess:
                // 0 no alert, 1 mild alert, 2 high alert , 4 ：vibrate only
//                pairingPeripheral?.writeValue(Data(bytes:[4]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
                break
            case .resetAuthFailed:
                break
            case .resetAuthSuccess:
                break
            case .firmwareCheckFailed:
                break
            case .firmwareCheckSuccess:
                break
            case .motorNotify:
                // 0 no alert, 1 mild alert, 2 high alert , 4 ：vibrate only
//                pairingPeripheral?.writeValue(Data(bytes:[1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
                break
            case .motorCall:
                // 0 no alert, 1 mild alert, 2 high alert , 4 ：vibrate only
//                pairingPeripheral?.writeValue(Data(bytes:[2]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
                break
            case .motorDisconnect:
                break
            case .motorSmartAlarm:
                break
            case .motorAlarm:
                break
            case .motorGoal:
                break
            case .motorAuth:
                break
            case .motorShutdown:
                break
            case .motorAuthSuccess:
                break
            case .motorTest:
                break
            case .pairCancel:
                break
            case .deviceMalfunction:
                break
            }
        }
    }
    
    func handleDeviceInfo(value: Data?) {
        guard value != nil else { return }
        
        // TODO refactor
        var uuid: [UInt8] = Array<UInt8>(repeatElement(0, count: value!.count))
        value!.copyBytes(to: &uuid, count: value!.count)
        var deviceId = ""
        for byte in uuid[0...7] {
            deviceId.append(String(format: "%02x", byte))
        }
        print("deviceId: \(deviceId)")
        
        
        let testBytes = value!.subdata(in: 0..<8)
        test = testBytes.withUnsafeBytes({ (pointer: UnsafePointer<Int32>) -> Int32 in
            return pointer.pointee
        })
        
        
        // UInt8 11, 10, 9, 8 (profile version x.x.x.x)
        var profileVersion = ""
        for byte in uuid[8...11].reversed() {
            profileVersion.append(String(format: uuid[8...11].reversed().index(of: byte) == 3 ? "%d" : "%d." , byte))
        }
        print("profileVersion: \(profileVersion)")
        
        // UInt8 15, 14, 13, 12 (firmawre version x.x.x.x)
        var firmwareVersion = ""
        for byte in uuid[12...15].reversed() {
            firmwareVersion.append(String(format: uuid[12...15].reversed().index(of: byte) == 3 ? "%d" : "%d." , byte))
            
        }
        print("firmwareVersion: \(firmwareVersion)")
        
        
        let feature = Int(uuid[4])
        let appearence = Int(uuid[5])
        let hardwareVersion = Int(uuid[6])
        print("feature:\(feature), appearance:\(appearence), hardwareversion:\(hardwareVersion)")
        
    
    }
    
    func handleBatteryInfo(value: Data?) {
        guard value != nil else { return }
        
        let levelData = value!.subdata(in: 0..<1)
        let lastChargeData = value!.subdata(in: 1..<7)
        let chargesCountData = value!.subdata(in: 7..<9)
        let statusData = value!.subdata(in: 9..<10)
        
        debugPrint("levelData: \(levelData), lastChargeData: \(lastChargeData), chargesCountData: \(chargesCountData), statusData: \(statusData)")
        
        let level = levelData.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> UInt8 in
            return pointer.pointee
        }
//        let chargesCount = chargesCountData.withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
        let chargesCount = chargesCountData.withUnsafeBytes { (pointer: UnsafePointer<[UInt8]>) -> UInt16 in
//            return pointer.pointee
            return pointer.withMemoryRebound(to: UInt16.self, capacity: 2, { (pointer: UnsafePointer<UInt16>) -> UInt16 in
                return pointer.pointee
            })
        }
        let status = statusData.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> UInt8 in
            return pointer.pointee
        }
        let lastCharge = lastChargeData.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Date in
            let calendar = Calendar(identifier: .gregorian)
            let timeZone = TimeZone(secondsFromGMT: 0)
            var dateComponents = DateComponents(calendar: calendar, timeZone: timeZone)
            dateComponents.year = 2000 + Int(pointer.pointee)
            print("\(pointer.pointee)")
            dateComponents.month = 1 + Int(pointer.advanced(by: 1).pointee)
            dateComponents.day = Int(pointer.advanced(by: 2).pointee)
            dateComponents.hour = Int(pointer.advanced(by: 3).pointee)
            dateComponents.minute = Int(pointer.advanced(by: 4).pointee)
            dateComponents.second = Int(pointer.advanced(by: 5).pointee)
            return dateComponents.date!
        }
        debugPrint("level: \(level), lastCharge: \(lastCharge), chargesCount: \(chargesCount), status: \(BatteryStatus(rawValue: status)!)")
    }
    
    func handleSensorData(value: Data?) {
        guard let value = value else { return } // observation: I think this is a good trick to unwrap optionals
        guard 0 == (value.count - 2) % 6 else {
            debugPrint("Unexpected data length. value: \(value)")
            return
        }
            
//        var count = 0, axis1 = 0, axis2 = 0, axis3: UInt16 = 0
        let countData = value.subdata(in: 0..<2)
        
        let count = countData.withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return pointer.pointee
        }
        
        debugPrint("count: \(count)")
        
//        let 
        
    }*/
}

