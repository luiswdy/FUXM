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
    private struct Consts {
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
    // TODO characteristic-ready rx to all characteristic dependent functions
    var areCharacteristicsReady: Variable<Bool> = Variable(false)
    
    // MARK - initializer
    required override init() {
        btManager = BluetoothManager(queue: DispatchQueue(label: Consts.bluetoothQueueLabel),
                                     options: Consts.btManagerConnOptions as [String : AnyObject]?)
        characteristicDict = [:]
        super.init()
    }
    
    // MARK - public methods
    func scanMiBands() -> Observable<RxBluetoothKit.ScannedPeripheral> {
        let scanDispatchQueue = DispatchQueue(label: Consts.peripheralScanQueueLabel)
        return btManager.scanForPeripherals(withServices: Consts.miBandServiceUUIDs, options: Consts.scanPeripheraOptions)
            .take(Consts.scanDuration, scheduler: ConcurrentDispatchQueueScheduler.init(queue: scanDispatchQueue))
    }
    
    func connect(_ peripheral: ScannedPeripheral) -> Observable<Void> {
        return connect(peripheral.peripheral)
    }
    
    func connect(_ peripheral: Peripheral) -> Observable<Void> {
        return peripheral.connect()
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
    
    
    
    func listenOnRestoreState() -> Observable<RestoredState> {
        return btManager.listenOnRestoredState()
    }
    
    func retrievePeripheral(withUUID uuid: UUID) -> Observable<Peripheral?> {
        return btManager.retrievePeripherals(withIdentifiers: [uuid]).map { return $0.first }   // get the first one as default, as we only pass one uuid
    }
    
    // TODO: sample
    func readDeviceInfo() -> Observable<FUDeviceInfo?> {
        return waitUntilCharacteristicsReady(closure: { return MiBandController.readValueFor(characteristic: self.characteristicDict[.deviceInfo], FUDeviceInfo.self) } )
    }
    
    // TODO FUDataInitiable for String ??
    func readDeviceName() -> Observable<String?> {
        return waitUntilCharacteristicsReady(closure: { [unowned self] in
            return self.characteristicDict[.deviceName]!.readValue().map({ (characteristic) -> String? in
                if let value = characteristic.value {
                    return String(data: value, encoding: .utf8)
                } else {
                    return nil
                }
            })
        })
    }

    func readUserInfo() -> Observable<FUUserInfo?> {
        return MiBandController.readValueFor(characteristic: characteristicDict[.userInfo], FUUserInfo.self)
    }
    
    func writeUserInfo(_ userInfo: FUUserInfo, salt: UInt8) -> Observable<Characteristic> {
        return MiBandController.writeValueTo(characteristic: characteristicDict[.userInfo],
                                             data: userInfo.data(salt: salt),
                                             type: .withResponse)
    }

    func vibrate(alertLevel: VibrationAlertLevel, ledColorForMildAlert: FULEDColor? = nil) {
        assert(characteristicDict[.deviceInfo] != nil && characteristicDict[.controlPoint] != nil, "characteristics are nil")
        var data: Data
        if let color = ledColorForMildAlert {
            data = Data(bytes: [VibrationAlertLevel.vibrateOnly.rawValue])
            MiBandController.writeValueTo(characteristic: characteristicDict[.alertLevel], data: data, type: .withoutResponse)
                .concat(
                    MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint],
                                                  data: Data(bytes:[ ControlPointCommand.setColorTheme.rawValue,
                                                                     color.red, color.green, color.blue, 0x1 as UInt8 ]),
                                                  type: .withResponse)
                )
                .publish().connect().dispose()
            
        } else {
            data = Data(bytes: [alertLevel.rawValue])
            MiBandController.writeValueTo(characteristic: characteristicDict[.alertLevel], data: data, type: .withoutResponse)
                .publish().connect().dispose()
        }
    }
    
    func bindPeripheral() -> Observable<Characteristic> {
        return MiBandController.writeValueTo(characteristic: characteristicDict[.pair],
                                             data: Data(bytes:FUByteArrayConverter.toUInt8Array(PairCommand.pair.rawValue)),
                                             type: .withResponse)
    }
    
    func readBatteryInfo() -> Observable<FUBatteryInfo?> {
        return waitUntilCharacteristicsReady(closure:  { [unowned self] in return MiBandController.readValueFor(characteristic: self.characteristicDict[.battery], FUBatteryInfo.self) } )
    }
    
    func readLEParams() -> Observable<FULEParams?> {
        return MiBandController.readValueFor(characteristic: characteristicDict[.leParams], FULEParams.self)
    }
    
    func writeLEParams(_ leParams: FULEParams) -> Observable<Characteristic> {
        return MiBandController.writeValueTo(characteristic: characteristicDict[.leParams], data: leParams.data() , type: .withResponse)
    }
    
    func readDateTime() -> Observable<FUDateTime?> {
        return MiBandController.readValueFor(characteristic: characteristicDict[.dateTime], FUDateTime.self)
    }
    
    func writeDateTime(_ date: Date) -> Observable<Characteristic> {
        var data = FUDateTime(date: date).data()
        data.append(FUDateTime().data())    // with empty date here
        return MiBandController.writeValueTo(characteristic: characteristicDict[.dateTime], data: data, type: .withResponse)
    }

    func writeDateTime(newerDate: FUDateTime, olderDate: FUDateTime) -> Observable<Characteristic> {
        var data = newerDate.data()
        data.append(olderDate.data())
        return MiBandController.writeValueTo(characteristic: characteristicDict[.dateTime], data: data, type: .withResponse)
    }
    
    func setNotificationAndMonitorUpdates(characteristic: FUCharacteristicUUID) -> Observable<Characteristic> {
        return waitUntilCharacteristicsReady(closure: { [unowned self] in
            return self.characteristicDict[characteristic]!.setNotificationAndMonitorUpdates()
        })
    }
    
    func readSensorData() -> Observable<FUSensorData?> {
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
    func reboot() -> Observable<Characteristic> {
        return MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint],
                                             data: Data(bytes: [ControlPointCommand.reboot.rawValue]),
                                             type: .withResponse)
    }

    func setWearPosition(position: FUWearPosition) -> Observable<Characteristic> {
        return MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint],
                                             data: Data(bytes: [ControlPointCommand.setWearPosition.rawValue, position.rawValue]),
                                             type: .withResponse)
    }
    
    func setFitnessGoal(steps: UInt16) -> Observable<Characteristic> {
        assert(characteristicDict[.controlPoint] != nil, "characteristic is nil")
        return MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint],
                                             data: Data(bytes: [ControlPointCommand.setFitnessGoal.rawValue, 0x0, UInt8(truncatingBitPattern: steps), UInt8(truncatingBitPattern: steps >> 8)]),
                                             type: .withResponse)
    }
    
    func fetchActivityData() -> Observable<Characteristic> {
        assert(characteristicDict[.controlPoint] != nil, "characteristic is nil")
        return MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint], data: Data(bytes: [ControlPointCommand.fetchData.rawValue]), type: .withResponse)
    }

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
    
    func setRealtimeStepsNofitication(start: Bool) -> Observable<Characteristic> {     // start = true ==> start, start = false ==> stop
        return MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint],
                                             data: Data(bytes: [ControlPointCommand.setRealtimeStepNotification.rawValue, start ? 1 : 0]),
                                             type: .withResponse)
    }
    
    func setSensorRead(start: Bool) -> Observable<Characteristic> {     // start = true ==> start sensor read, start = false ==> stop sensor read
        return MiBandController.writeValueTo(characteristic: characteristicDict[.controlPoint],
                                             data: Data(bytes: [ControlPointCommand.getSensorData.rawValue, start ? 1 : 0]),
                                             type: .withResponse)
        
    }
    // MARK - private methods
    
    // generic function to wait characteristic dict ready
    private func waitUntilCharacteristicsReady<T>(closure: @escaping () -> Observable<T>) -> Observable<T>{
        return areCharacteristicsReady.asObservable().filter { (isReady) -> Bool in
            return isReady
        }.flatMap{ (_) -> Observable<T> in
            return closure()
        }
    }
    
    // Generic utility function
    static private func readValueFor<T: FUDataInitiable>(characteristic: Characteristic?, _ type: T.Type) -> Observable<T?> {
        assert(characteristic != nil, "characteristic is nil")
        if let characteristic = characteristic {
            return characteristic.readValue().map { (characteristic) -> T? in
                return T(data: characteristic.value)
            }
        } else {
            return Observable<T?>.create {
                $0.onNext(nil)
                $0.onCompleted()
                return Disposables.create() // no-op disposable
            }
        }
    }
    
    static private func writeValueTo(characteristic: Characteristic?, data: Data?, type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        assert(characteristic != nil, "characteristic is nil")
        if let characteristic = characteristic, let data = data {
            return characteristic.writeValue(data, type: type)
        } else {
            return Observable<Characteristic>.create {
                $0.onCompleted()    // straight finishes the signal
                return Disposables.create()  // no-op disposable
            }
        }
    }
}
