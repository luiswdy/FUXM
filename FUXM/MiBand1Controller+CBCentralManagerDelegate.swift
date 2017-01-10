//
//  MiBand1Controller+CBCentralManagerDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 1/5/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import Foundation
import CoreBluetooth

/*
extension MiBand1Controller: CBCentralManagerDelegate {
    
    // core bluetooth central manager delegate
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(#function)
        print("Connected to \(peripheral.name)")
//        peripheral.delegate = self
        storePairedPeripheralUUID(peripheral.identifier)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(#function)
        
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        /*
         services available
         1. FEE0: Mili service
         2. FEE1
         3. FEE7
         4. 1802: Immediate Alert Service (IAS) - used for icoming call, finding band ..etc
         REF: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.service.immediate_alert.xml&u=org.bluetooth.service.immediate_alert.xml
         
         */
        
        struct Holder {
            static var isWaitingToShowPeripheralList  = false
        }
        
        print("\(#function) peripheral: \(peripheral), advertisementData: \(advertisementData), rssi: \(RSSI)")
        
        discorevedPeripherals.insert(peripheral)
        
        let scanQueue = DispatchQueue(label: "bluetoothScanQueue",
                                      qos: .userInitiated,
                                      attributes: .concurrent,
                                      autoreleaseFrequency: .workItem,
                                      target: nil)
        
        if !(Holder.isWaitingToShowPeripheralList) {
            Holder.isWaitingToShowPeripheralList = true
            scanQueue.asyncAfter(wallDeadline: .now() + .seconds(3)) {
                let peripheralAlert = UIAlertController(title: "Devices found", message: "Choose the device to pair with", preferredStyle: .actionSheet)
                if self.discorevedPeripherals.count > 0 {
                    for peripheral in self.discorevedPeripherals {
                        if let name = peripheral.name {
                            peripheralAlert.addAction(
                                UIAlertAction(title: name,
                                              style: .default,
                                              handler: { [weak peripheral] (action) in
                                                print("\(peripheral)")
                                                // Connect the chosen peripheral
                                                if let peripheral = peripheral {
                                                    self.miBandControl?.connect(peripheral)
                                                }
                                                
                                }))
                        }
                    }
                    peripheralAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                        print("\(action.title)")
                    }))
                    self.present(peripheralAlert, animated: true, completion: nil)
                } else {
                    // TODO show alert of no device found
                    print("No device found")
                }
                self.miBandControl?.stopScan()
                Holder.isWaitingToShowPeripheralList = false
            }
        }
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(#function) : error: \(error)")
        
        
        
    }
    
    /*CoreBluetooth] API MISUSE: <CBCentralManager: 0x155555f0> has no restore identifier but the delegate implements the centralManager:willRestoreState: method. Restoring will not be supported */
    
    //    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    //        print(#function)
    //
    //    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("bluetooth state: \(central.state.rawValue)")
        
        switch central.state {
        case .poweredOn:
            if let pairedPeripheralUUID = miBandControl?.loadPairedPeripheralUUID() {
                if let foundPeripheral = miBandControl?.retrivePeripherals(withIdentifiers: [pairedPeripheralUUID]).first {
                    self.pairedPeripheral = foundPeripheral
                    miBandControl?.connect(self.pairedPeripheral!)
                }
                //                central.retrievePeripherals(withIdentifiers: [pairedPeripheralUUID])
                //                central.retrieveConnectedPeripherals(withServices: <#T##[CBUUID]#>)
            }
            break
        default:
            break
        }
        
    }
    
    //    func centralManager(_ central: CBCentralManager, didRetrieveConnectedPeripherals peripherals: [CBPeripheral]) {
    //        print("peripherals: \(peripherals)")
    //
    //    }
    //
    //    func centralManager(_ central: CBCentralManager, didRetrievePeripherals peripherals: [CBPeripheral]) {
    //        print("peripherals: \(peripherals)")
    //        
    //    }
    
}

 */
