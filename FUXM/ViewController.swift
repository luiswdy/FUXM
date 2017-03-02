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
import HealthKit

class ViewController: UIViewController {
    // MARK - properties
    let miController = MiBandController()
    let disposeBag = DisposeBag()
    var deviceInfo: FUDeviceInfo?
    var activityReader: FUActivityReader?
    let healthStore = HKHealthStore()
    
    // MARK - Interface Builder outlets
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var stopScanBtn: UIButton!
    @IBOutlet var vibrateBtn: UIButton!
    @IBOutlet var setAlarm: UIButton!
    @IBOutlet var datePicker: UIDatePicker!
    
    struct Consts {
        static let hudFlashDelay = 1.0
    }
    
    // MARK - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        miController.btState.subscribe(onNext:  { [unowned self] in // self holds miController
            switch $0 {
            case .poweredOn:
                DispatchQueue.main.async {
                    self.enableButtonsAtPoweredOn()
                }
                break
            default:
                debugPrint("bluetooth state: \($0)")
                    self.disableButtonsNonPoweredOn()
                break
            }
        }).addDisposableTo(disposeBag)
        miController.listenOnRestoreState().subscribe(onNext: { [weak self] (restoredState) in
            if let strongSelf = self, let peripheral = restoredState.peripherals.first {
                strongSelf.miController.connect(peripheral).publish().connect().addDisposableTo(strongSelf.disposeBag)  // TODO subscribe next complete error ..etc
            }
        }, onError: { (error) in
            debugPrint("listen to retored state failed: \(error)")
        }, onCompleted: { 
            debugPrint("\(#function) completed")
        }, onDisposed: {
            debugPrint("disposed")
        }).addDisposableTo(self.disposeBag)
        
        //        miController = MiBandController(delegate: self)   // TEST
        //        if let boundPeripheralUUID = MiBandUserDefaults.loadBoundPeripheralUUID(),
        //           let foundPeripheral = miController!.retrievePeripheral(withUUID: boundPeripheralUUID) {
        //            activePeripheral = foundPeripheral
        //            miController!.connect(activePeripheral!)
        ////            miController!.readDeviceInfo()  // TODO: move to "when characteristics are ready"!!!
        //        }
        
        // TODO: restore (better implementation and maybe move it to proper spot)
        if let boundPeripheralUUID = MiBandUserDefaults.loadBoundPeripheralUUID() {
            miController.retrievePeripheral(withUUID: boundPeripheralUUID).subscribe(onNext: { [weak self] (peripheral) in      // self holds miController
                if let peripheral = peripheral, let strongSelf = self {
                    strongSelf.miController.connect(peripheral).subscribe(onCompleted: {
                    
                    
                    
                        strongSelf.miController.readDeviceInfo().subscribe(onNext: {
                            strongSelf.deviceInfo = $0
                            debugPrint("deviceInfo: \(strongSelf.deviceInfo)")
                            strongSelf.miController.setNotificationAndMonitorUpdates(characteristic: .notification)
                                .subscribe(onNext: {
                                    strongSelf.handleNotifications(from: $0)
                                },
                                           onError: { debugPrint("\($0)")},
                                           onCompleted: { debugPrint("completed")},
                                           onDisposed: { debugPrint("disposed")}).addDisposableTo(strongSelf.disposeBag)
                            let userInfo = FUUserInfo(uid: 123, gender: .male, age: 37, height: 170, weight: 64, type: .normal, alias: "Luis")
                            strongSelf.miController.bindPeripheral().publish().connect().addDisposableTo(strongSelf.disposeBag)
                            strongSelf.miController.writeUserInfo(userInfo, salt: strongSelf.deviceInfo!.salt).publish().connect().addDisposableTo(strongSelf.disposeBag)
                            
                            strongSelf.miController.writeDateTime(Date()).publish().connect().addDisposableTo(strongSelf.disposeBag)   // sync current datatime
                            
                            
                            DispatchQueue.main.async {
                                HUD.flash(.label("Reconnected"), delay: Consts.hudFlashDelay)
                                self?.vibrateBtn.isEnabled = true
                            }
                            
                            
                            
                        }).addDisposableTo(strongSelf.disposeBag)
                        
                    
                    
                    
                    
                    } ).addDisposableTo(strongSelf.disposeBag)
                    
                    }

            }, onError: { (error) in
                debugPrint("\(error)")
            }, onCompleted: {
                debugPrint("completed")
            }, onDisposed: {
                debugPrint("disposed")
            }).addDisposableTo(self.disposeBag)
        }
        
        
        
        // health kit
        self.healthStore.requestAuthorization(toShare: [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, HKObjectType.quantityType(forIdentifier: .stepCount)!],
                                              read: [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, HKObjectType.quantityType(forIdentifier: .stepCount)!]) { (isSuccess, error) in
                                                if !isSuccess {
                                                    debugPrint("error: \(error)")
                                                }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - IBActions
    @IBAction func scan(sender: AnyObject) {
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
    
    @IBAction func stopScan(sender: AnyObject) { // manually stop scanning
        debugPrint("\(#function) sender: \(sender)")
        //        cbCentralManager.stopScan()
    }
    
    @IBAction func vibrate(sender: UIButton) {
        miController.vibrate(alertLevel: .mildAlert, ledColorForMildAlert: FULEDColor(red: 6, green: 0, blue: 6))
        
        
        
        // TEST
        self.miController.setNotificationAndMonitorUpdates(characteristic: .activityData).subscribe(onNext: { [unowned self] (characteristic) in
            assert(self.deviceInfo != nil, "deviceInfo is nil")
            objc_sync_enter(self.miController)
            
            if self.activityReader == nil || self.activityReader?.state == .done {  // start new reading session
                self.activityReader = FUActivityReader(supportHeartRate: self.deviceInfo!.supportHeartRate())
            }
            self.activityReader?.handleIncomingData(characteristic.value).subscribe(onNext: { (activities) in
                
                activities.forEach( { debugPrint( "* activity: \($0)" )} )
                
            }, onError: { (error) in
                debugPrint("error: \(error)")
            }, onCompleted: {
                // read a complete chunk, reset activity reader
                debugPrint("completed")
                self.activityReader = nil
            }, onDisposed: {
                debugPrint("disposed")
            }).addDisposableTo(self.disposeBag)
            
            objc_sync_exit(self.miController)
            
        }, onError: { (error) in
            debugPrint("\(error)")
        }, onCompleted: {
            debugPrint("completed")
        }, onDisposed: {
            debugPrint("disposed")
        }).addDisposableTo(self.disposeBag)
        self.miController.fetchActivityData().publish().connect().addDisposableTo(self.disposeBag)
        // END TEST
    }
    
    @IBAction func setAlarm(sender: UIButton) {
        let dateTime = FUDateTime(date: datePicker.date)
        
        // TODO set time everytime open the app? (at auth )
        
        
        self.miController.setAlarm(alarm: FUAlarmClock(index: 0, enable: true, dateTime: dateTime, enableSmartWakeUp: false, repetition: .everyDay)).publish().connect().addDisposableTo(self.disposeBag)
    }
    
    // MARK - private methods
    func enableButtonsAtPoweredOn() {
        scanBtn.isEnabled = true
        stopScanBtn.isEnabled = true
    }
    
    func disableButtonsNonPoweredOn() {
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
                        self.miController.connect(peripheral).subscribe(
                            onError: {
                            debugPrint("\($0)")
                            DispatchQueue.main.async {
                                HUD.flash(.error , delay: Consts.hudFlashDelay)
                            }
                        }, onCompleted: {
                            // TEST
                            MiBandUserDefaults.storeBoundPeripheralUUID(peripheral.peripheral.identifier)
                            // END TEST
                            DispatchQueue.main.async {
                                HUD.flash(.success, delay: Consts.hudFlashDelay)
                            }
                            // TEST TRY
                            self.miController.readDeviceInfo().subscribe(onNext: { [unowned self] in
                                self.deviceInfo = $0
                                debugPrint("deviceInfo: \(self.deviceInfo)")
                                self.miController.setNotificationAndMonitorUpdates(characteristic: .notification)
                                    .subscribe(onNext: { [unowned self] in
                                        self.handleNotifications(from: $0)
                                        },
                                               onError: { debugPrint("\($0)")},
                                               onCompleted: { debugPrint("completed")},
                                               onDisposed: { debugPrint("disposed")}).addDisposableTo(self.disposeBag)
                                let userInfo = FUUserInfo(uid: 1, gender: .male, age: 37, height: 170, weight: 63, type: .normal, alias: "Luis Wu")
                                self.miController.writeUserInfo(userInfo, salt: self.deviceInfo!.salt).publish().connect().addDisposableTo(self.disposeBag)
                                self.miController.bindPeripheral().publish().connect().addDisposableTo(self.disposeBag)
                                
                                
                                self.miController.writeDateTime(Date()).publish().connect().addDisposableTo(self.disposeBag)   // sync current datatime
                                
                                
                                DispatchQueue.main.async {
                                    self.vibrateBtn.isEnabled = true
                                }
                                
                            }).addDisposableTo(self.disposeBag)
                            
                            // END TEST TRY
                        }).addDisposableTo(self.disposeBag)
                    }))
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleNotifications(from characteristic: Characteristic) {
        debugPrint("\(#function) characteristic: \(characteristic.uuid)")
        if let value = characteristic.value,
            let notification = FUNotification(rawValue: value.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt8 in return pointer.pointee })),
            value.count > 0 {
            debugPrint("incoming notification: \(notification)")
            switch notification {
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
                self.miController.vibrate(alertLevel: .mildAlert, ledColorForMildAlert: FULEDColor(red: 0, green: 5, blue: 6))
                break
            case .authFailed:
                self.miController.vibrate(alertLevel: .vibrateOnly)
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
}

