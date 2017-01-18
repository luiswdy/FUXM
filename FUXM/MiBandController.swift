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

// Values may receive from
// optional func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
// after setNotify to characteristic notification (0xff03)
enum FUNotification: UInt8 {
    case
    //    unknown = -0x1,
    normal                  = 0x0,
    firmwareUpdateFailed    = 0x1,
    firmwareUpdateSuccess   = 0x2,
    connParamUpdateFailed   = 0x3,
    connParamUpdateSuccess  = 0x4,
    authSuccess             = 0x5,
    authFailed              = 0x6,
    fitnessGoalAchieved     = 0x7,
    setLatencySuccess       = 0x8,
    resetAuthFailed         = 0x9,
    resetAuthSuccess        = 0x10,
    firmwareCheckFailed     = 0x11,
    firmwareCheckSuccess    = 0x12,
    motorNotify             = 0x13,
    motorCall               = 0x14,
    motorDisconnect         = 0x15,
    motorSmartAlarm         = 0x16,
    motorAlarm              = 0x17,
    motorGoal               = 0x18,
    motorAuth               = 0x19,
    motorShutdown           = 0x20,
    motorAuthSuccess        = 0x21,
    motorTest               = 0x22,
    // I remember I got 0x18 !? while keeping shaking mi band at starting the app
    pairCancel              = 0xef,
    deviceMalfunction       = 0xff
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
    
    
    // Generic utility function
    static private func readValueFor<T: FUDataInitiable>(characteristic: Characteristic?, _ type: T.Type) -> Observable<T?> {
        if let characteristic = characteristic {
            return characteristic.readValue().map { (characteristic) -> T? in
                return T(data: characteristic.value)
            }
        } else {
            return Observable<T?>.create( {
                $0.onNext(nil)
                return Disposables.create() // no-op disposable
            } )
        }
    }
    
    func retrievePeripheral(withUUID uuid: UUID) -> Observable<Peripheral?> {
        return btManager.retrievePeripherals(withIdentifiers: [uuid]).map { return $0.first }   // get the first one as default, as we only pass one uuid
    }
    
    func readDeviceInfo() -> Observable<FUDeviceInfo?> {
        assert(characteristicDict[.deviceInfo] != nil, "characteristic is nil")
        return MiBandController.readValueFor(characteristic: characteristicDict[.deviceInfo], FUDeviceInfo.self)
    }

    func readUserInfo() -> Observable<FUUserInfo?> {
        assert(characteristicDict[.userInfo] != nil, "characteristic is nil")
        return MiBandController.readValueFor(characteristic: characteristicDict[.userInfo], FUUserInfo.self)
    }
    
    func writeUserInfo(_ userInfo: FUUserInfo, salt: UInt8) -> Observable<Characteristic> {
        assert(characteristicDict[.userInfo] != nil, "characteristic is nil")
        return characteristicDict[.userInfo]!.writeValue(userInfo.data(salt: salt), type: .withResponse)
    }

    func vibrate(alertLevel: VibrationAlertLevel, ledColorForMildAlert: FULEDColor? = nil) {
        assert(characteristicDict[.deviceInfo] != nil && characteristicDict[.controlPoint] != nil, "characteristics are nil")
        var data: Data
        if let color = ledColorForMildAlert {
            data = Data(bytes: [VibrationAlertLevel.vibrateOnly.rawValue])
            characteristicDict[.alertLevel]!.writeValue(data, type: .withoutResponse)
                .concat(
                    characteristicDict[.controlPoint]!.writeValue(
                    Data(bytes:[ ControlPointCommand.setColorTheme.rawValue,
                                 color.red, color.green, color.blue, 0x1 as UInt8 ]),
                    type: .withResponse)
                )
                .publish().connect().dispose()
            
        } else {
            data = Data(bytes: [alertLevel.rawValue])
            characteristicDict[.alertLevel]!.writeValue(data, type: .withoutResponse).publish().connect().dispose()
        }
    }
    
    func bindPeripheral() -> Observable<Characteristic> {
        assert(characteristicDict[.pair] != nil, "characteristic is nil")
        return characteristicDict[.pair]!.writeValue(Data(bytes:FUByteArrayConverter.toUInt8Array(PairCommand.pair.rawValue)), type: .withResponse)
    }
    
    func readBatteryInfo() -> Observable<FUBatteryInfo?> {
        assert(characteristicDict[.battery] != nil, "characteristic is nil")
        return MiBandController.readValueFor(characteristic: characteristicDict[.battery], FUBatteryInfo.self)
    }
    
    func readLEParams() -> Observable<FULEParams?> {
        assert(characteristicDict[.leParams] != nil, "characteristic is nil")
        return MiBandController.readValueFor(characteristic: characteristicDict[.leParams], FULEParams.self)
    }
//    
//    func writeLEParams(_ leParams: FULEParams) {
//        guard let leParamsCharacteristic = characteristicsAvailable[.leParams] else { return }
//        self.activePeripheral?.writeValue(leParams.data(), for: leParamsCharacteristic, type: .withResponse)
//    }
    
    func readDateTime() -> Observable<FUDateTime?> {
        assert(characteristicDict[.dateTime] != nil, "characteristic is nil")
        return MiBandController.readValueFor(characteristic: characteristicDict[.dateTime], FUDateTime.self)
    }
    
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
    func setNotify(enable: Bool, characteristic: FUCharacteristicUUID) -> Observable<Characteristic> {
        assert(characteristicDict[characteristic] != nil, "characteristic is nil")
//        return characteristicDict[characteristic]!.setNotifyValue(enable)
        return characteristicDict[characteristic]!.setNotificationAndMonitorUpdates()
    }
    
    func readSensorData() -> Observable<FUSensorData?> {
        assert(characteristicDict[.sensorData] != nil, "characteristic is nil")
        return MiBandController.readValueFor(characteristic: characteristicDict[.sensorData], FUSensorData.self)
    }
    
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
    func setAlarm(alarm: FUAlarmClock) -> Observable<Characteristic> {
        assert(characteristicDict[.controlPoint] != nil, "characteristic is nil")
        var data = Data(bytes: [ControlPointCommand.setTimer.rawValue])
        data.append(alarm.data())
        return characteristicDict[.controlPoint]!.writeValue(data, type: .withResponse)
    }
    
    func getMACAddress() -> Observable<Characteristic> {
        assert(characteristicDict[.macAddress] != nil, "characteristic is nil")
        return characteristicDict[.macAddress]!.readValue()
    }
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
