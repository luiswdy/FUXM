//
//  MiBandController+CBCentralManagerDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import CoreBluetooth.CBCentralManager
import AudioToolbox //TEST

extension MiBandController: CBCentralManagerDelegate {
    // MARK - CBCentralManagerDelegate - monitoring connections with peripherals
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral)")
        peripheral.delegate = self  // IMPORTANT: Must assign the delegate!
        delegate?.didConnectPeripheral(peripheral)
        peripheral.discoverServices(Consts.miBandServiceUUIDs)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral), error: \(error)")
        // TODO: invoke connection failed callback / delegate function
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral), error: \(error)")
        // TODO: invoke connection disconnected callback / delegate function
    }
    
    // MARK - CBCentralManagerDelegate - Discovering and retrieving peripherals
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral), advertisementData: \(advertisementData), rssi:\(RSSI)")
        discoveredPeripherals.append(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didRetrieveConnectedPeripherals peripherals: [CBPeripheral]) {
        debugPrint("\(#function) central: \(central), peripherals: \(peripherals)")
    }
    
    func centralManager(_ central: CBCentralManager, didRetrievePeripherals peripherals: [CBPeripheral]) {
        debugPrint("\(#function) central: \(central), peripherals: \(peripherals)")
    }
    
    // MARK - CBCentralManagerDelegate - Monitoring changesto the central manager's state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        debugPrint("\(#function) central: \(central)")
        switch central.state {
        case .poweredOn:
            // try to re-connect device if exists
//            if let boundPeripheral = boundPeripheral {
            if let activePeripheral = activePeripheral {    // TODO boundPeripheral uuid  to reconnect?
                central.connect(activePeripheral)
            } else {
                debugPrint("Not re-connecting")
            }
            break
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            debugPrint("\(central.state)")
            // TODO: invoke couldn't connection callback / delegate function
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as! [CBPeripheral];
        let services = dict[CBCentralManagerRestoredStateScanServicesKey];
        let scanOptions = dict[CBCentralManagerRestoredStateScanOptionsKey];
        debugPrint("\(#function) central: \(central), dict:\(dict), peripherals: \(peripherals), services: \(services), scanOptions:\(scanOptions)")
        
        // reconnect here
        if let peripheral = peripherals.first {
            central.connect(peripheral, options: Consts.peripheralConnOptions)
        }
        
    }
}
