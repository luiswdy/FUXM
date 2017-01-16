//
//  ViewController.swift
//  FUXM
//
//  Created by Luis Wu on 12/7/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import UIKit
import CoreBluetooth.CBPeripheral

class ViewController: UIViewController {
    // MARK - properties
    var miController: MiBandController?
    var activePeripheral: CBPeripheral?
    
    // MARK - Interface Builder outlets
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var stopScanBtn: UIButton!
    @IBOutlet var vibrateBtn: UIButton!
    
    // MARK - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableButtons() // TEST
//        miController = MiBandController(delegate: self)   // TEST
        if let boundPeripheralUUID = MiBandUserDefaults.loadBoundPeripheralUUID(),
           let foundPeripheral = miController!.retrievePeripheral(withUUID: boundPeripheralUUID) {
            activePeripheral = foundPeripheral
            miController!.connect(activePeripheral!)
//            miController!.readDeviceInfo()  // TODO: move to "when characteristics are ready"!!!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - IBActions
    @IBAction func scan(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
        scanMiBands()
    }
    
    @IBAction func stopScan(sender: UIButton) { // manually stop scanning
        debugPrint("\(#function) sender: \(sender)")
//        cbCentralManager.stopScan()
    }
    
    @IBAction func vibrate(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
        miController!.vibrate(alertLevel: .mildAlert, ledColorForMildAlert: FULEDColor(red: 6, green: 0, blue: 6))
//        miController!.readActivityData()
        miController!.setNotify(enable: true, characteristic: .activityData)
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
    
    func scanMiBands() {
        miController?.scanMiBand()
    }
    
    /*
    
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

