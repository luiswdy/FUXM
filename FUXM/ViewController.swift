//
//  ViewController.swift
//  FUXM
//
//  Created by Luis Wu on 12/7/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import PKHUD

class ViewController: UIViewController {
    // MARK - properties
    var miController = MiBandController()
    var disposeBag = DisposeBag()
    var deviceInfo: FUDeviceInfo?
    
    // MARK - Interface Builder outlets
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var stopScanBtn: UIButton!
    @IBOutlet var vibrateBtn: UIButton!
    
    struct Consts {
        static let hudFlashDelay = 1.0
    }
    
    // MARK - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        miController.btState.subscribe(onNext:  { [unowned self] in // self holds miController
            switch $0 {
            case .poweredOn:
                self.enableButtons()
                break
            default:
                debugPrint("bluetooth state: \($0)")
                break
            }
        }).addDisposableTo(disposeBag)
//        miController = MiBandController(delegate: self)   // TEST
//        if let boundPeripheralUUID = MiBandUserDefaults.loadBoundPeripheralUUID(),
//           let foundPeripheral = miController!.retrievePeripheral(withUUID: boundPeripheralUUID) {
//            activePeripheral = foundPeripheral
//            miController!.connect(activePeripheral!)
////            miController!.readDeviceInfo()  // TODO: move to "when characteristics are ready"!!!
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - IBActions
    @IBAction func scan(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
        var peripherals: [RxBluetoothKit.ScannedPeripheral] = []
        HUD.show(.labeledProgress(title: "Scanning", subtitle: "Looking for Mi bands" ))
        miController.scanMiBands().subscribe(onNext: { (peripheral) in
            peripherals.append(peripheral)
        }, onError: { (error) in
            DispatchQueue.main.async {
                self.present(FUMessageFactory.simpleMessageView(title: "Error", message: "\(error)"),
                             animated: true,
                             completion: nil)
            }
        }, onDisposed:  { [unowned self] in // miController is held by self
            DispatchQueue.main.async {
                HUD.hide(animated: true)
                self.showPeripherals(peripherals)
            }
        }).addDisposableTo(disposeBag)
    }
    
    @IBAction func stopScan(sender: UIButton) { // manually stop scanning
        debugPrint("\(#function) sender: \(sender)")
//        cbCentralManager.stopScan()
    }
    
    @IBAction func vibrate(sender: UIButton) {
        miController.vibrate(alertLevel: .mildAlert, ledColorForMildAlert: FULEDColor(red: 6, green: 0, blue: 6))
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
    
    func showPeripherals(_ peripherals: [RxBluetoothKit.ScannedPeripheral]) {
        let alert = UIAlertController(title: "Devices found", message: "Choose the device to pair with", preferredStyle: .actionSheet)
        for peripheral in peripherals {
            if let name = peripheral.advertisementData.localName {
                alert.addAction(
                    UIAlertAction(title: name, style: .default, handler: { [unowned self] (action) in
                        HUD.show(.label("Preparing mili services"))
                        self.miController.connect(peripheral).subscribe(onError: {
                            debugPrint("\($0)")
                            DispatchQueue.main.async {
                                HUD.flash(.error , delay: Consts.hudFlashDelay)
                            }
                        }, onCompleted: {
                            DispatchQueue.main.async {
                                HUD.flash(.success, delay: Consts.hudFlashDelay)
                                // TEST TRY
                                self.miController.readDeviceInfo().subscribe(onNext: { [unowned self] in
                                    self.deviceInfo = FUDeviceInfo(data: $0.value)
                                    debugPrint("deviceInfo: \(self.deviceInfo)")
                                    self.miController.setNotify(enable: true, characteristic: .notification)
                                        .subscribe(onNext: { debugPrint("\($0)")
                                        },
                                                   onError: { debugPrint("\($0)")},
                                                   onCompleted: { debugPrint("completed")},
                                                   onDisposed: { debugPrint("disposed")}).addDisposableTo(self.disposeBag)
                                    let userInfo = FUUserInfo(uid: 123, gender: .male, age: 37, height: 174, weight: 64, type: .normal, alias: "Luis")
                                    self.miController.writeUserInfo(userInfo, salt: self.deviceInfo!.salt).publish().connect().addDisposableTo(self.disposeBag)
                                    self.miController.bindPeripheral().publish().connect().addDisposableTo(self.disposeBag)
                                    let dateTime = FUDateTime(year: 17, month: 1, day: 1, hour: 6, minute: 30, second: 00)
                                    self.miController.setAlarm(alarm: FUAlarmClock(index: 0, enable: true, dateTime: dateTime, enableSmartWakeUp: true, repetition: FURepetition.weekDays)).subscribe(onCompleted: { debugPrint("Alarm set") }).addDisposableTo(self.disposeBag)
                                }).addDisposableTo(self.disposeBag)
                            }
                        }).addDisposableTo(self.disposeBag)
                    }))
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
    
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
//                pairingPeripheral?.writeValue(Data(bytes:[1]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
                break
            case .motorCall:
                // 0 no alert, 1 mild alert, 2 high alert , 4 ：vibrate only
//                pairingPeripheral?.writeValue(Data(bytes:[2]), for: characteristicsAvailable[.alertLevel]!, type: .withoutResponse)
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
    
    }*/
}

