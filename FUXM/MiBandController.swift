//
//  MiBandController.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import CoreBluetooth
import RxBluetoothKit
import RxSwift

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
        static let btManagerConnOptions: [String: Any] = [ CBCentralManagerOptionRestoreIdentifierKey: Consts.centralManagerId ]
        static let peripheralConnOptions: [String: Any] = [ CBConnectPeripheralOptionNotifyOnConnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnDisconnectionKey : true,
                                                            CBConnectPeripheralOptionNotifyOnNotificationKey : true
        ]
        static let scanDuration: Double = 2 // in sec
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
        static let characteristicsUUIDs: [CBUUID] = { () -> [CBUUID] in
            var uuids = [CBUUID]()
            for uuid in FUCharacteristicUUID.allValues {
                uuids.append(CBUUID(string: String(uuid.rawValue, radix :GlobalConsts.hexRadix)))
            }
            return uuids
        }()
    }
    
    // MARK - properties
    var btManager: BluetoothManager
    var characteristicDict: [FUCharacteristicUUID : Characteristic]
    var btState: Observable<BluetoothState> {
        return btManager.rx_state
    }
    
//    var activityDataReader: FUActivityReader?
    
    // MARK - initializer
    required override init() {
        btManager = BluetoothManager(queue: DispatchQueue(label: Consts.bluetoothQueueLabel),
                                     options: Consts.btManagerConnOptions as [String : AnyObject]?)
        characteristicDict = [:]
        super.init()
    }
    
    // MARK - public methods
    func scanMiBands() -> Observable<RxBluetoothKit.ScannedPeripheral> {
        let scanDispatchQueue = DispatchQueue(label: "scanning")
        return btManager.scanForPeripherals(withServices: Consts.miBandServiceUUIDs, options: Consts.scanPeripheraOptions)
            .take(Consts.scanDuration, scheduler: ConcurrentDispatchQueueScheduler.init(queue: scanDispatchQueue))
    }
    
    func connect(_ peripheral: ScannedPeripheral) -> Observable<Void> {
        return peripheral.peripheral.connect()
            .flatMap { $0.discoverServices(Consts.miBandServiceUUIDs) }
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics(nil) }
            .flatMap { Observable.from($0) }
            .map({ (characteristic) -> Void in
                debugPrint("characteristics: \(characteristic)")
                if let rawUUID = UInt16(characteristic.uuid.uuidString, radix: GlobalConsts.hexRadix),
                    let convertedUUID = FUCharacteristicUUID(rawValue: rawUUID) {
                    self.characteristicDict[convertedUUID] = characteristic
                } else {
                    debugPrint("Unknown characteristic: \(characteristic.uuid.uuidString)")
                }
            })
    }
    
//    func retrievePeripheral(withUUID uuid: UUID) -> CBPeripheral? {
//        return centralManager.retrievePeripherals(withIdentifiers: [uuid]).first
//    }
//    
//    func readDeviceInfo() {
//        guard let deviceInfoCharacteristic = characteristicsAvailable[.deviceInfo] else { return }
//        self.activePeripheral?.readValue(for: deviceInfoCharacteristic)
//        
//    }
//    
//    func readUserInfo() {
//        guard let userInfoCharacteristic = characteristicsAvailable[.userInfo] else { return }
//        self.activePeripheral?.readValue(for: userInfoCharacteristic)
//    }
//    
//    func writeUserInfo(_ userInfo: FUUserInfo, salt: UInt8) {
//        guard let userInfoCharacteristic = characteristicsAvailable[.userInfo] else { return }
//        self.activePeripheral?.writeValue(userInfo.data(salt: salt), for: userInfoCharacteristic, type: .withResponse)
//    }
//    
    func vibrate(alertLevel: VibrationAlertLevel, ledColorForMildAlert: FULEDColor? = nil) {
        guard let alertLevelChar = characteristicDict[.alertLevel], let controlPointChar = characteristicDict[.controlPoint]else { return }
        var data: Data
        if let color = ledColorForMildAlert {
            data = Data(bytes: [VibrationAlertLevel.vibrateOnly.rawValue])
            alertLevelChar.writeValue(data, type: .withoutResponse).publish().connect().dispose()
            controlPointChar.writeValue(Data(bytes:[ ControlPointCommand.setColorTheme.rawValue, color.red, color.green, color.blue, 0x1 as UInt8 ]), type: .withResponse).publish().connect().dispose()
        } else {
            data = Data(bytes: [alertLevel.rawValue])
            alertLevelChar.writeValue(data, type: .withoutResponse).publish().connect().dispose()
        }
    }
//
//    func bindPeripheral(_ peripheral: CBPeripheral) {
//        guard let pairCharacteristic = characteristicsAvailable[.pair] else { return }
//        self.activePeripheral?.writeValue(Data(bytes:[ PairCommand.pair.rawValue ]), for: pairCharacteristic, type: .withResponse)
//    }
//    
//    func readBatteryInfo() {
//        guard let batteryInfoCharacteristic = characteristicsAvailable[.battery] else { return }
//        self.activePeripheral?.readValue(for: batteryInfoCharacteristic)
//    }
//    
//    func readLEParams() {
//        guard let leParamsCharacteristic = characteristicsAvailable[.leParams] else { return }
//        self.activePeripheral?.readValue(for: leParamsCharacteristic)
//    }
//    
//    func writeLEParams(_ leParams: FULEParams) {
//        guard let leParamsCharacteristic = characteristicsAvailable[.leParams] else { return }
//        self.activePeripheral?.writeValue(leParams.data(), for: leParamsCharacteristic, type: .withResponse)
//    }
//    
//    func readDateTime() {
//        guard let dateTimeCharacteristic = characteristicsAvailable[.dateTime] else { return }
//        self.activePeripheral?.readValue(for: dateTimeCharacteristic)
//    }
//    
//    func writeDateTime(_ date: Date) {
//        guard let dateTimeCharacteristic = characteristicsAvailable[.dateTime] else { return }
//        var data = FUDateTime(date: date).data()
//        data.append(FUDateTime().data())
//        self.activePeripheral?.writeValue(data, for: dateTimeCharacteristic, type: .withResponse)
//    }
//    
//    func writeDateTime(newerDate: FUDateTime, olderDate: FUDateTime) {
//        guard let dateTimeCharacteristic = characteristicsAvailable[.dateTime] else { return }
//        var data = newerDate.data()
//        data.append(olderDate.data())
//        self.activePeripheral?.writeValue(data, for: dateTimeCharacteristic, type: .withResponse)
//    }
//    
//    func setNotify(enable: Bool, characteristic: FUCharacteristicUUID) {
//        guard let notifyCharacteristic = characteristicsAvailable[characteristic] else { return }
////        if characteristic == .activityData { self.activityDataReader = FUActivityReader() }
//        self.activePeripheral?.setNotifyValue(enable, for: notifyCharacteristic)
//    }
//    
//    func readSensorData() {
//        guard let sensorDataCharacteristic = characteristicsAvailable[.sensorData] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [1]), for: sensorDataCharacteristic, type: .withResponse)
//        self.activePeripheral?.readValue(for: sensorDataCharacteristic)
//    }
//    
//    func startSensorData() {    // for notify sensor data
//        guard let sensorDataCharacteristic = characteristicsAvailable[.sensorData] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [1]), for: sensorDataCharacteristic, type: .withResponse)
//    }
//    
//    func readActivityData() {
//        guard let activityDataCharacteristic = characteristicsAvailable[.activityData] else { return }
//        self.activePeripheral?.readValue(for: activityDataCharacteristic)
//    }
//    
//    func reboot() {
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.reboot.rawValue]), for: controlPointCharacteristic, type: .withResponse)
//    }
//    
//    func setWearPosition(position: FUWearPosition) {
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.setWearPosition.rawValue, position.rawValue]), for: controlPointCharacteristic, type: .withResponse)
//    }
//    
//    func setFitnessGoal(steps: UInt16) {
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.setFitnessGoal.rawValue, 0x0, UInt8(truncatingBitPattern: steps), UInt8(truncatingBitPattern: steps >> 8)]), for: controlPointCharacteristic, type: .withResponse)
//    }
//    
//    func fetchData() {
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.fetchData.rawValue]), for: controlPointCharacteristic, type: .withResponse)
//    }
//    
//    func setAlarm(alarm: FUAlarmClock) {
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        var data = Data(bytes: [ControlPointCommand.setTimer.rawValue])
//        data.append(alarm.data())
//        self.activePeripheral?.writeValue(data, for: controlPointCharacteristic, type: .withResponse)
//    }
//    
//    func setRealtimeStepsNofitication(start: Bool) {     // start = true ==> start, start = false ==> stop
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.setRealtimeStepNotification.rawValue, start ? 1 : 0]), for: controlPointCharacteristic, type: .withResponse)
//    
//    }
//    
//    func setSensorRead(start: Bool) {     // start = true ==> start sensor read, start = false ==> stop sensor read
//        guard let controlPointCharacteristic = characteristicsAvailable[.controlPoint] else { return }
//        self.activePeripheral?.writeValue(Data(bytes: [ControlPointCommand.getSensorData.rawValue, start ? 1 : 0]), for: controlPointCharacteristic, type: .withResponse)
//        
//    }
    // MARK - private methods
}
