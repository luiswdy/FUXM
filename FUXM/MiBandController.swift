//
//  MiBandController.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import CoreBluetooth

// NOTE: This class support ONLY miband 1 (might probably work with 1A with limited support)
struct GlobalConsts {
    static let hexRadix = 16
}

class MiBandController: NSObject {
    // constants
    struct Consts {
        static let bundleID = Bundle.main.bundleIdentifier != nil ? Bundle.main.bundleIdentifier! : "mi_band_controller."
        static let bluetoothQueueLabel = bundleID + ".bluetooth_queue"
        static let centralManagerId = bundleID + ".central_manager"
        static let centralManagerConnOptions: [String: Any] = [ CBCentralManagerOptionRestoreIdentifierKey: Consts.centralManagerId ]
        static let peripheralConnOptions: [String: Any] = [ CBConnectPeripheralOptionNotifyOnConnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnDisconnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnNotificationKey : true
        ]
        static let scanDuration = 5 // in sec
        static let miBandServiceUUIDs: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in FUServiceUUID.allKeys {
                uuids.append(CBUUID(string: uuid))
            }
            return uuids
        }()
        static let characteristics: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in FUCharacteristicUUID.allKeys {
                uuids.append(CBUUID(string: uuid))
            }
            return uuids
        }()
    }
    
    var centralManager: CBCentralManager
    var discoveredPeripherals: [CBPeripheral]
    var boundPeripheral: CBPeripheral?
//    var servicesAvailable: [FUServiceUUID : CBService]?
    var characteristicsAvailable: [FUCharacteristicUUID : CBCharacteristic]
    
    required override init() {
        discoveredPeripherals = []
        characteristicsAvailable = [:]
        centralManager = CBCentralManager(delegate: nil,
                                          queue: DispatchQueue(label: Consts.bluetoothQueueLabel, attributes: [.concurrent]),
                                          options: Consts.centralManagerConnOptions)
        super.init()
        centralManager.delegate = self
    }
    
}
