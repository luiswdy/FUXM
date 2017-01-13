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

enum VibrationAlertLevel: UInt8 {
    case
    noAlert     = 0x0,
    mildAlert   = 0x1,
    hignAlert   = 0x2,
    vibrateOnly = 0x4
}

class FULEDColor {
    private static let minValue: UInt8 = 0
    private static let maxValue: UInt8 = 6
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    
    required init?(red: UInt8, green: UInt8, blue: UInt8) {    // failable initializer
        if !(FULEDColor.minValue ... FULEDColor.maxValue ~= red) ||         // check if rgb are within the range
           !(FULEDColor.minValue ... FULEDColor.maxValue ~= green) ||
           !(FULEDColor.minValue ... FULEDColor.maxValue ~= blue) {
            return nil
        } else {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
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
    
    
    // MARK - initializer
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
    
    
    // MARK - public methods
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
    
    func retrievePeripheral(withUUID uuid: UUID) -> CBPeripheral? {
        return centralManager.retrievePeripherals(withIdentifiers: [uuid]).first
    }
    
    func readDeviceInfo() {
        guard let deviceInfoCharacteristic = characteristicsAvailable[.deviceInfo] else { return }
        self.activePeripheral?.readValue(for: deviceInfoCharacteristic)
        
    }
    
    func readUserInfo() {
        guard let userInfoCharacteristic = characteristicsAvailable[.userInfo] else { return }
        self.activePeripheral?.readValue(for: userInfoCharacteristic)
    }
    
    func writeUserInfo(_ userInfo: FUUserInfo, salt: UInt8) {
        guard let userInfoCharacteristic = characteristicsAvailable[.userInfo] else { return }
        self.activePeripheral?.writeValue(userInfo.data(salt: 0x3e), for: userInfoCharacteristic, type: .withResponse)  // TODO: get actual salt
    }
    
    func vibrate(alertLevel: VibrationAlertLevel, ledColorForMildAlert: FULEDColor? = nil) {
        guard let alertLevelCharacteristic = characteristicsAvailable[.alertLevel], let controlPointCharacteristic = characteristicsAvailable[.controlPoint]else { return }
        var data: Data!
        if let color = ledColorForMildAlert {
            data = Data(bytes: [VibrationAlertLevel.vibrateOnly.rawValue])
            self.activePeripheral?.writeValue(data, for: alertLevelCharacteristic, type: .withoutResponse)
            self.activePeripheral?.writeValue(Data(bytes:[ ControlPointCommand.setColorTheme.rawValue, color.red, color.green, color.blue, 0x1 as UInt8 ]), for: controlPointCharacteristic, type:.withResponse)
        } else {
            data = Data(bytes: [alertLevel.rawValue])
            self.activePeripheral?.writeValue(data, for: alertLevelCharacteristic, type: .withoutResponse)
        }
    }
    
    func bindPeripheral(_ peripheral: CBPeripheral) {
        guard let pairCharacteristic = characteristicsAvailable[.pair] else { return }
        self.activePeripheral?.writeValue(Data(bytes:[ 0x2 ]), for: pairCharacteristic, type: .withResponse)
    }
    
    // MARK - private methods
}
