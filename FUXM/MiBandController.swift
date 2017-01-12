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
    // MARK - constants
    struct Consts {
        static let bundleID = Bundle.main.bundleIdentifier != nil ? Bundle.main.bundleIdentifier! : "mi_band_controller."
        static let bluetoothQueueLabel = bundleID + ".bluetooth_queue"
        static let peripheralScanQueueLabel = bundleID + ".bluetooth_peripheral_scan_queue"
        static let centralManagerId = bundleID + ".central_manager"
        static let centralManagerConnOptions: [String: Any] = [ CBCentralManagerOptionRestoreIdentifierKey: Consts.centralManagerId ]
        static let peripheralConnOptions: [String: Any] = [ CBConnectPeripheralOptionNotifyOnConnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnDisconnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnNotificationKey : true
        ]
        static let scanDuration: Double = 5 // in sec
        static let miBandServiceUUIDs: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in FUServiceUUID.allValues {
                uuids.append(CBUUID(string: String(uuid.rawValue, radix: GlobalConsts.hexRadix)))
            }
            return uuids
        }()
        static let scanPeripheraOptions = [ CBCentralManagerScanOptionAllowDuplicatesKey: false,
                                            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: miBandServiceUUIDs
        ] as [String : Any]
        static let characteristics: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in FUCharacteristicUUID.allValues {
                uuids.append(CBUUID(string: String(uuid.rawValue, radix :GlobalConsts.hexRadix)))
            }
            return uuids
        }()
    }
    
    // MARK - properties
    private var centralManager: CBCentralManager
    var discoveredPeripherals: [CBPeripheral]
    var activePeripheral: CBPeripheral?
    var boundPeripheral: CBPeripheral?
//    var servicesAvailable: [FUServiceUUID : CBService]?
    var characteristicsAvailable: [FUCharacteristicUUID : CBCharacteristic]
    var delegate: MiBandControllerDelegate?
    var isScanning: Bool {
        get {
            return centralManager.isScanning
        }
    }
//    private(set)
    
    
    // initializer
    required init(delegate: MiBandControllerDelegate? = nil) {
        discoveredPeripherals = []
        characteristicsAvailable = [:]
        centralManager = CBCentralManager() // to init centralManager before super.init()
        super.init()
        centralManager = CBCentralManager(delegate: self,
                                          queue: DispatchQueue(label: Consts.bluetoothQueueLabel, attributes: [.concurrent]),
                                          options: Consts.centralManagerConnOptions)
        self.delegate = delegate
    }
    
    func scanMiBand() {
        discoveredPeripherals.removeAll()
        let scanQueue = DispatchQueue(label: Consts.peripheralScanQueueLabel)
        centralManager.scanForPeripherals(withServices: Consts.miBandServiceUUIDs, options: Consts.scanPeripheraOptions)
        scanQueue.asyncAfter(deadline: .now() + Consts.scanDuration) {
            self.centralManager.stopScan()
            self.delegate?.onMiBandsDiscovered(peripherals: self.discoveredPeripherals)
        }
    }
    
    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: Consts.peripheralConnOptions)
    }
    
    func readDeviceInfo() {
        guard let deviceInfoCharacteristic = characteristicsAvailable[.deviceInfo] else { return }
        self.activePeripheral?.readValue(for: deviceInfoCharacteristic)
        
    }
}
