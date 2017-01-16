    //
//  ViewController+MiBandControllerDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import UIKit
import CoreBluetooth.CBPeripheral

extension ViewController: MiBandControllerDelegate {
    func onMiBandsDiscovered(peripherals: [CBPeripheral]) {
        if peripherals.count > 0 {
            let alert = UIAlertController(title: "Devices found", message: "Choose the device to pair with", preferredStyle: .actionSheet)
            for peripheral in peripherals {
                if let name = peripheral.name {
                    alert.addAction(
                        UIAlertAction(title: name, style: .default, handler: { [unowned self] (action) in
                            self.miController?.connect(peripheral)
                        }))
                }
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Devices not found", message: "Devices not foud", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func didConnectPeripheral(_ peripheral: CBPeripheral) {
        MiBandUserDefaults.storeBoundPeripheralUUID(peripheral.identifier)
    }
    
    func onUpdateDeviceInfo(_ deviceInfo: FUDeviceInfo?, isNotifying: Bool, error: Error?) {
        // TODO
//        miController?.readUserInfo()    // TEST
        debugPrint("DEBUG - \(deviceInfo)")
    }
    
    func onUpdateUserInfo(_ userInfo: FUUserInfo?, error: Error?) {
        // TODO
        debugPrint("\(userInfo)")
    }
    
    func onUpdateBatteryInfo(_ batteryInfo: FUBatteryInfo?, isNotifying: Bool, error: Error?) {
        debugPrint("\(batteryInfo)")
    }
    
    func onUpdateLEParams(_ leParams: FULEParams?, isNotifying: Bool, error: Error?) {
        debugPrint("\(leParams)")
    }
    
    func onUpdateDateTime(_ dateTime: FUDateTime?, error: Error?) {
        // TODO
        debugPrint("\(dateTime)")
    }
    
    func onUpdateSensorData(_ sensorData: FUSensorData?, isNotifying: Bool, error: Error?) {
        debugPrint("\(sensorData)")
    }
    
    func onUpdateRealtimeSteps(_ steps: UInt16, isNotifying: Bool, error: Error?) {
        debugPrint("realtimeSteps: \(steps)")
    }
}
