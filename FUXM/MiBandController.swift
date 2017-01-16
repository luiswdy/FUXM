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

enum FUWearPosition: UInt8 {
    case leftHand = 0, rightHand
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
    var activityDataReader: FUActivityReader?
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
        self.activePeripheral?.writeValue(userInfo.data(salt: salt), for: userInfoCharacteristic, type: .withResponse)
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
        self.activePeripheral?.writeValue(Data(bytes:[ PairCommand.pair.rawValue ]), for: pairCharacteristic, type: .withResponse)
    }
    
    func readBatteryInfo() {
        guard let batteryInfoCharacteristic = characteristicsAvailable[.battery] else { return }
        self.activePeripheral?.readValue(for: batteryInfoCharacteristic)
    }
    
    func readLEParams() {
        guard let leParamsCharacteristic = characteristicsAvailable[.leParams] else { return }
        self.activePeripheral?.readValue(for: leParamsCharacteristic)
    }
    
    func writeLEParams(_ leParams: FULEParams) {
        guard let leParamsCharacteristic = characteristicsAvailable[.leParams] else { return }
        self.activePeripheral?.writeValue(leParams.data(), for: leParamsCharacteristic, type: .withResponse)
    }
    
    func readDateTime() {
        guard let dateTimeCharacteristic = characteristicsAvailable[.dateTime] else { return }
        self.activePeripheral?.readValue(for: dateTimeCharacteristic)
    }
    
    func writeDateTime(_ date: Date) {
        guard let dateTimeCharacteristic = characteristicsAvailable[.dateTime] else { return }
        var data = FUDateTime(date: date).data()
        data.append(FUDateTime().data())
        self.activePeripheral?.writeValue(data, for: dateTimeCharacteristic, type: .withResponse)
    }
    
    func writeDateTime(newerDate: FUDateTime, olderDate: FUDateTime) {
        guard let dateTimeCharacteristic = characteristicsAvailable[.dateTime] else { return }
        var data = newerDate.data()
        data.append(olderDate.data())
        self.activePeripheral?.writeValue(data, for: dateTimeCharacteristic, type: .withResponse)
    }
    
    func setNotify(enable: Bool, characteristic: FUCharacteristicUUID) {
        guard let notifyCharacteristic = characteristicsAvailable[characteristic] else { return }
        if characteristic == .activityData { self.activityDataReader = FUActivityReader() }
        self.activePeripheral?.setNotifyValue(enable, for: notifyCharacteristic)
    }
    
    func readSensorData() {
        guard let sensorDataCharacteristic = characteristicsAvailable[.sensorData] else { return }
        self.activePeripheral?.writeValue(Data(bytes: [1]), for: sensorDataCharacteristic, type: .withResponse)
        self.activePeripheral?.readValue(for: sensorDataCharacteristic)
    }
    
    func startSensorData() {    // for notify sensor data
        guard let sensorDataCharacteristic = characteristicsAvailable[.sensorData] else { return }
        self.activePeripheral?.writeValue(Data(bytes: [1]), for: sensorDataCharacteristic, type: .withResponse)
    }
    
    func readActivityData() {
        guard let activityDataCharacteristic = characteristicsAvailable[.activityData] else { return }
        self.activePeripheral?.readValue(for: activityDataCharacteristic)
    }
    
    func reboot() {
        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.reboot.rawValue]), for: controlPointCharacteristic, type: .withResponse)
    }
    
    func setWearPosition(position: FUWearPosition) {
        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.setWearPosition.rawValue, position.rawValue]), for: controlPointCharacteristic, type: .withResponse)
    }
    
    func setFitnessGoal(steps: UInt16) {
        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.setFitnessGoal.rawValue, 0x0, UInt8(truncatingBitPattern: steps), UInt8(truncatingBitPattern: steps >> 8)]), for: controlPointCharacteristic, type: .withResponse)
    }
    // MARK - private methods
}
