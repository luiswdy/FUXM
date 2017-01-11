//
//  ViewController.swift
//  FUXM
//
//  Created by Luis Wu on 12/7/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import UIKit
import CoreBluetooth

enum ServiceUUID: String {  // 2 bytes, little endian. NOTE: UInt8 servers as a byte
    case ias = "1802",
    miBand = "FEE0",
    miBand2 = "FEE1",
    unknown = "FEE7"
    
    static let allValues = [miBand, miBand2, unknown, ias]
}

enum UserDefaultsKeys: String {
    case pairPeripheralUUID = "pair_peripheral_uuid"
}

enum CharacteristicUUID: String {   // 2 bytes, little endian
    case alertLevel = "2A06",   // characteristics of service immediateAlert (IAS)
    deviceInfo = "FF01",   // characteristics of service miBand
    deviceName = "FF02",     // 0xFF02
    notification = "FF03",   // 0xFF03
    userInfo = "FF04",       // 0xFF04
    controlPoint = "FF05",   // 0xFF05
    realtimeSteps = "FF06",  // 0xFF06
    activityData = "FF07",   // 0xFF07
    firmwareData = "FF08",   // 0xFF08
    leParams = "FF09",       // 0xFF09
    dateTime = "FF0A",       // 0xFF0A
    statistics = "FF0B",     // 0xFF0B
    battery = "FF0C",        // 0xFF0C
    test = "FF0D",           // 0xFF0D
    sensorData = "FF0E",     // 0xFF0E
    pair = "FF0F",           // 0xFF0F
    weird = "FF10",           // ????
    unknown1 = "FEDD",  // characteristics of service miBand2
    unknown2 = "FEDE",
    unknown3 = "FEDF",
    unknown4 = "FEE0",
    unknown5 = "FEE1",
    unknown6 = "FEE2",
    unknown7 = "FEE3",
    unknown8 = "FEC7",  // characteristics of unknown service
    unknown9 = "FEC8",
    unknown10 = "FEC9"
    
    static let iasCharacteristics = [alertLevel]
    static let miBandCharacteristics = [deviceInfo, deviceName, notification, userInfo, controlPoint, realtimeSteps, activityData, firmwareData, leParams, dateTime, statistics, battery, test, sensorData, pair]
    static let miBand2Characteristics = [unknown1, unknown2, unknown3, unknown4, unknown5, unknown6, unknown7]
    static let unknownCharacteristics = [unknown8, unknown9, unknown10]
    static let allValues = CharacteristicUUID.iasCharacteristics
        + CharacteristicUUID.miBandCharacteristics
        + CharacteristicUUID.miBand2Characteristics
        + CharacteristicUUID.unknownCharacteristics
}

enum Notifications: UInt8 {
    case
//    unknown = -0x1,
    normal = 0x0,
    firmwareUpdateFailed,   // 1
    firmwareUpdateSuccess,  // 2
    connParamUpdateFailed,  // 3
    connParamUpdateSuccess, // 4
    authSuccess,            // 5        <- after 15 comes to here
    authFailed,             // 6
    fitnessGoalAchieved,    // 7
    setLatencySuccess,      // 8
    resetAuthFailed,        // 9
    resetAuthSuccess,       // 10   a
    firmwareCheckFailed,    // 11   b
    firmwareCheckSuccess,   // 12   c
    motorNotify,            // 13   d
    motorCall,              // 14   e
    motorDisconnect,        // 15   f
    motorSmartAlarm,        // 16   10
    motorAlarm,             // 17   11
    motorGoal,              // 18   12
    motorAuth,              // 19   13
    motorShutdown,          // 20   14
    motorAuthSuccess,       // 21   15 <-
    motorTest,              // 22   16
    
                                    //18 !?
    pairCancel = 0xef,
    deviceMalfunction = 0xff
}

enum ControlPointCommand: UInt8 {
    /*
     MBControlPointColor = 14,
     MBControlPointWearPosition,
     MBControlPointRealtimeSteps,
     MBControlPointStopSync,
     MBControlPointSensorData,
     MBControlPointStopVibrate
     
 public static final byte COMMAND_SET_WEAR_LOCATION = 0xf;
 public static final byte COMMAND_STOP_SYNC_DATA = 0x11;
 public static final byte COMMAND_STOP_MOTOR_VIBRATE = 0x13;
 public static final byte COMMAND_SET_REALTIME_STEPS_NOTIFICATION = 0x3;
 public static final byte COMMAND_SET_REALTIME_STEP = 0x10;
 
 // Test HR
 public static final byte COMMAND_SET_HR_SLEEP = 0x0;
 public static final byte COMMAND_SET__HR_CONTINUOUS = 0x1;
 public static final byte COMMAND_SET_HR_MANUAL = 0x2;
 
 public static final byte COMMAND_GET_SENSOR_DATA = 0x12;
 
  FURTHER COMMANDS: unchecked therefore left commented
 
 
	public static final byte COMMAND_FACTORY_RESET = 0x9t;
 
	public static final int COMMAND_SET_COLOR_THEME = et;
 */
 
    case stopCallRemind = 0,
    callRemind,
    setRealtimeStepNotification = 3,
    setTimer,
    setFitnessGoal,
    fetchData,
    firmwareInfo,
    sendNotification,
    reset,
    confirmActivityDataTransferComplete,
    sync,
    reboot,
    setLEDColor = 14,
    setWearPosition
    
    
    
    
    
}

/*
 public static final int TYPE_DEEP_SLEEP = 4;
 public static final int TYPE_LIGHT_SLEEP = 5;
 public static final int TYPE_ACTIVITY = -1;
 public static final int TYPE_UNKNOWN = -1;
 public static final int TYPE_NONWEAR = 3;
 public static final int TYPE_CHARGING = 6;
 */

enum ActivityType: Int8 {
    case activity = -1,
    nonWear = 3,
    deepSleep,
    lightSleep,
    charging
}

/*
 public static final byte DEVICE_BATTERY_NORMAL = 0;
 public static final byte DEVICE_BATTERY_LOW = 1;
 public static final byte DEVICE_BATTERY_CHARGING = 2;
 public static final byte DEVICE_BATTERY_CHARGING_FULL = 3;
 public static final byte DEVICE_BATTERY_CHARGE_OFF = 4;
 */

enum BatteryStatus: UInt8 {
    case normal = 0,
    low,
    charging,
    chargingFull,
    chargeOff
}


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var cbCentralManager: CBCentralManager!
    var discoveredPeripherals: [CBPeripheral] = []
    var pairingPeripheral: CBPeripheral?
    var servicesAvailable: [ServiceUUID : CBService] = [:]
    var characteristicsAvailable: [CharacteristicUUID : CBCharacteristic] = [:]
    
    // TEST
    
    var test : Int32 = 0
    // END TEST
    
    
    
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var stopScanBtn: UIButton!
    @IBOutlet var vibrateBtn: UIButton!
    
    struct Consts {
        //        static let bluetoothQueueLabel = "com.example.FUXM.bluetoothQueue"
        static let centralManagerId = "com.example.FUXM.centralmanager"
        static let centralManagerConnOptions: [String: Any] = [ CBCentralManagerOptionRestoreIdentifierKey: Consts.centralManagerId ]
        static let peripheralConnOptions: [String: Any] = [ CBConnectPeripheralOptionNotifyOnConnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnDisconnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnNotificationKey : true
        ]
        static let scanDuration = 3 // in sec
        static let miBandServiceUUIDs: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in ServiceUUID.allValues {
                uuids.append(CBUUID(string: uuid.rawValue))
            }
            return uuids
        }()
        static let characteristics: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in CharacteristicUUID.allValues {
                uuids.append(CBUUID(string: uuid.rawValue))
            }
            return uuids
        }()
    }
    
    // MARK - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //        let cbCentralManagerQueue = DispatchQueue(label: Consts.bluetoothQueueLabel)
        //        cbCentralManager = CBCentralManager(delegate: self, queue: cbCentralManagerQueue, options: Consts.centralMangerConnOptions)
        cbCentralManager = CBCentralManager(delegate: self, queue: nil, options: Consts.centralManagerConnOptions)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - IBActions
    @IBAction func scan(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
        guard !cbCentralManager.isScanning else { return }
        scanMiBands()
    }
    
    @IBAction func stopScan(sender: UIButton) { // manually stop scanning
        debugPrint("\(#function) sender: \(sender)")
        cbCentralManager.stopScan()
    }
    
    @IBAction func vibrate(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
        // TODO
//        pairingPeripheral?.writeValue(Data(bytes:[0x1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
//        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setWearPosition.rawValue, 0]), for: characteristicsAvailable[CharacteristicUUID.controlPoint]!, type: .withResponse)
//        pairingPeripheral?.writeValue(Data(bytes:[0x1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)   // workable!
        
        
//        pairingPeripheral?.writeValue(Data(bytes:[1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)   // workable!
//        pairingPeripheral?.writeValue(Data(bytes:[4]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)   // workable!
//        pairingPeripheral?.writeValue(Data(bytes:[2]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)   // workable!
        pairingPeripheral?.writeValue(Data(bytes:[1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)   // workable!
        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.reboot.rawValue]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
    }
    
    // MARK - CBCentralManagerDelegate - monitoring connections with peripherals
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral)")
        // TODO - discover and construct services, write PAIRED to mi band, store paired peripheral's UUID
        peripheral.delegate = self
        peripheral.discoverServices(Consts.miBandServiceUUIDs)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral), error: \(error)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugPrint("\(#function) central: \(central), peripheral: \(peripheral), error: \(error)")
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
        var errorMessage: String? = nil
        
        debugPrint("\(#function) central: \(central)")
        switch central.state {
        case .poweredOn:
            enableButtons()
            
            // try to re-connect device if exists
            if let pairedPeripheralUUID = self.loadPairedPeripheralUUID(),
               let foundPeripheral = cbCentralManager.retrievePeripherals(withIdentifiers: [pairedPeripheralUUID]).first {
                    self.pairingPeripheral = foundPeripheral    // need a strong ref to keep the peripheral
                    cbCentralManager.connect(foundPeripheral)
            } else {
                debugPrint("Not re-connecting")
            }
            break
        case .unknown:
            debugPrint("unknown")
            errorMessage = "Unknown"
            break
        case .resetting:
            debugPrint("resetting")
            errorMessage = "Resetting"
            break
        case .unsupported:
            debugPrint("unsupported")
            errorMessage = "Unsupported"
            break
        case .unauthorized:
            debugPrint("unauthorized")
            errorMessage = "Unauthorized"
            break
        case .poweredOff:
            debugPrint("poweredOff")
            disableButtons()
            errorMessage = "Powered Off"
            break
        }
        
        if let error = errorMessage {
            let alert = UIAlertController(title: "Bluetooth error", message: "Error: \(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
        let services = dict[CBCentralManagerRestoredStateScanServicesKey];
        let scanOptions = dict[CBCentralManagerRestoredStateScanOptionsKey];
        debugPrint("\(#function) central: \(central), dict:\(dict), peripherals: \(peripherals), services: \(services), scanOptions:\(scanOptions)")
    }
    
    // MARK - CBPeripheralDelegate - Discovering services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) error: \(error)")
        if let services = peripheral.services {
            for service in services {
                servicesAvailable[ServiceUUID(rawValue: service.uuid.uuidString)!] = service
                peripheral.discoverCharacteristics(Consts.characteristics, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) service: \(service) error: \(error)")
    }
    
    // MARK - CBPeripheralDelegate - Discovering characteristics and characteristics descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) service: \(service) error: \(error)")
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                characteristicsAvailable[CharacteristicUUID(rawValue: characteristic.uuid.uuidString)!] = characteristic    // TODO: crash due to receiving characteristic of UUID FED0
            }
        }
        
        let gotAllCharacteristics = peripheral.services?.reduce(true, { (result, service) -> Bool in
            return result && (service.characteristics != nil)
        })
        if let ready = gotAllCharacteristics, ready == true {
            storePairedPeripheralUUID(peripheral.identifier)
            setupForPeripheral()
        }
        
        
        
//        if let characteristics = service.characteristics {
//            for characteristic in characteristics {
//                peripheral.discoverDescriptors(for: characteristic)
//            }
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error)")
        
//        if let descriptors = characteristic.descriptors {
//            for descriptor in descriptors {
//                debugPrint("descriptor: \(descriptor), uuidString: \(descriptor.uuid.uuidString)")
//            }
//        }
    }
    
    // MARK - CBPeripheralDelegate - Retrieving characteristic and characteristic descriptor values
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error) value: \(characteristic.value)")
        guard nil == error else {
            debugPrint("Error occurred: \(error)")
            return
        }
        if characteristic.isNotifying {
            handleNotifications(from: characteristic)
        }
        
        switch CharacteristicUUID(rawValue: characteristic.uuid.uuidString)! {
        case .alertLevel:
            // TODO
            break
        case .deviceInfo:
            // TODO
            handleDeviceInfo(value: characteristic.value)
            break
        case .deviceName:
            // TODO
            break
        case .notification:
            // TODO
            break
        case .userInfo:
            // TODO
            break
        case .controlPoint:
            // TODO
            break
        case .realtimeSteps:
            // TODO
            break
        case .activityData:
            // TODO
            break
        case .firmwareData:
            // TODO
            break
        case .leParams:
            // TODO
            break
        case .dateTime:
            // TODO
            break
        case .statistics:
            // TODO
            break
        case .battery:
            handleBatteryInfo(value: characteristic.value)
            // TODO
            break
        case .test:
            // TODO
            break
        case .sensorData:
            // TODO
            handleSensorData(value: characteristic.value)
            break
        case .pair:
            // TODO
            break
        case .unknown1, .unknown2, .unknown3, .unknown4, .unknown5,
             .unknown6, .unknown7, .unknown8, .unknown9, .unknown10, .weird:
            debugPrint("unknown characteristics. value \(characteristic.value)")
            break
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) descriptor: \(descriptor) error: \(error)")
        
    }
    
    // MARK - CBPeripheralDelegate - Writing characteristic and characteristic descriptor values
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error)")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) descriptor: \(descriptor) error: \(error)")
        
    }
    
    // MARK - CBPeripheralDelegate - Managing notifications for a characteristic's value
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) characteristic: \(characteristic) error: \(error)")
        handleNotifications(from: characteristic)
    }
    
    // MARK - CBPeripheralDelegate - Retrieving a Peripheral’s Received Signal Strength Indicator (RSSI) Data
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        debugPrint("\(#function) peripheral: \(peripheral) RSSI: \(RSSI) error: \(error)")
        
    }
    
    // MARK - CBPeripheralDelegate - Monitoring Changes to a Peripheral’s Name or Services
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        debugPrint("\(#function) peripheral: \(peripheral)")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        debugPrint("\(#function) peripheral: \(peripheral) invalidatedServices: \(invalidatedServices)")
        
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
    
    func setupForPeripheral() {
        pairingPeripheral?.setNotifyValue(true, for: characteristicsAvailable[.notification]!)
        let lowLatencyData = createLatency(minConnInterval: 39, maxConnInterval: 49, latency: 0, timeout: 500, advertisementInterval: 0)
        pairingPeripheral?.writeValue(lowLatencyData, for: characteristicsAvailable[CharacteristicUUID.leParams]!, type: .withResponse)
        pairingPeripheral?.readValue(for: characteristicsAvailable[CharacteristicUUID.dateTime]!)
        pairingPeripheral?.writeValue(Data(bytes:[0x2]), for: characteristicsAvailable[CharacteristicUUID.pair]!, type: .withResponse)
        pairingPeripheral?.readValue(for: characteristicsAvailable[CharacteristicUUID.deviceInfo]!)
//        let userInfo = createUserInfo(uid: test, gender: 1, age: 36, height: 170, weight: 64, type: 1, alias: "Luis")
//        let userInfo = Data(bytes: [0x73, 0xdc, 0x32, 0x0, 0x2, 0x19, 0xaf, 0x46, 0x0, 0x6c, 0x75, 0x69, 0x73, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x25]) // HERE! the user info format
//        pairingPeripheral?.writeValue(userInfo, for: characteristicsAvailable[CharacteristicUUID.userInfo]!, type: .withResponse)
        
        pairingPeripheral?.readValue(for: characteristicsAvailable[.userInfo]!)
        
        // check authentication needed
        
        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setWearPosition.rawValue, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
        
        // setHeartrateSleepSupport (may not apply)
        
        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setFitnessGoal.rawValue, 0x0, UInt8(truncatingBitPattern: 10000), UInt8(truncatingBitPattern: 10000 >> 8)]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
        
        pairingPeripheral?.setNotifyValue(true, for: characteristicsAvailable[.realtimeSteps]!)
        pairingPeripheral?.setNotifyValue(true, for: characteristicsAvailable[.activityData]!)
        pairingPeripheral?.setNotifyValue(true, for: characteristicsAvailable[.battery]!)
        pairingPeripheral?.setNotifyValue(true, for: characteristicsAvailable[.sensorData]!)
        
        let nowData = createDate(newerDate: Date())
        pairingPeripheral?.writeValue(nowData, for: characteristicsAvailable[.dateTime]!, type: .withResponse)
        pairingPeripheral?.readValue(for: characteristicsAvailable[.battery]!)
        let highLatencyData = createLatency(minConnInterval: 460, maxConnInterval: 500, latency: 0, timeout: 500, advertisementInterval: 0)
        pairingPeripheral?.writeValue(highLatencyData, for: characteristicsAvailable[CharacteristicUUID.leParams]!, type: .withResponse)
        
        // TODO : set initialized
        
        
//        pairingPeripheral?.readValue(for: characteristicsAvailable[CharacteristicUUID.userInfo]!)
        // TEST
        
//        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.sendNotification.rawValue, 1]), for: characteristicsAvailable[CharacteristicUUID.controlPoint]!, type: .withoutResponse)
//        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setLEDColor.rawValue, 6, 0, 6, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
//        pairingPeripheral?.writeValue(Data(bytes:[0x1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
        
        pairingPeripheral?.writeValue(Data(bytes:[0x12, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
        
        pairingPeripheral?.readValue(for: characteristicsAvailable[.sensorData]!)
        
        
//        pairingPeripheral?.writeValue(Data(bytes:[ControlPointCommand.setLEDColor.rawValue, 0, 0, 6, 1]), for: characteristicsAvailable[.controlPoint]!, type: .withResponse)
    }
    
    
    
    func loadPairedPeripheralUUID() -> UUID? {
        if let uuidString = UserDefaults.standard.string(forKey: UserDefaultsKeys.pairPeripheralUUID.rawValue) {
            return UUID(uuidString: uuidString)
        } else {
            return nil
        }
    }
    
    func storePairedPeripheralUUID(_ uuid: UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey: UserDefaultsKeys.pairPeripheralUUID.rawValue)
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
                pairingPeripheral?.writeValue(Data(bytes:[1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
                break
            case .motorCall:
                // 0 no alert, 1 mild alert, 2 high alert , 4 ：vibrate only
                pairingPeripheral?.writeValue(Data(bytes:[2]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
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
        
    }
}

