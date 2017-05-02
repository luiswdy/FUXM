//
//  FUDashboardViewController.swift
//  FUXM
//
//  Created by Luis Wu on 1/21/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import UIKit
import RxSwift
import RxBluetoothKit
import PKHUD

class FUDashboardViewController: UIViewController, FUTabBarChildViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var batteryLevel: UILabel!
    @IBOutlet var batteryStatus: UILabel!
    @IBOutlet var boundMiband: UILabel!
    @IBOutlet var realtimeSteps: UILabel!
    private var internalMibandController: MiBandController!
    private var disposeBag =  DisposeBag()
    
    
    
    var deviceInfo: FUDeviceInfo?
    
    
    
    struct Consts {
        static let hudFlashDelay = 1.0
    }
    
    // MARK - protocol FUTabBarChildViewController
    var mibandController: MiBandController {
        get {
            return internalMibandController
        }
        set {
            internalMibandController = newValue
        }
    }
    
    // MARK - initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    // MARK - life cycle
    override func viewDidLoad() {
        setup()
        reload(sender: nil)
    }
    
    func refresh(_ sender: UIRefreshControl) {
        debugPrint("refreshing")
        reload(sender: sender)
    }
    
    // MARK - private methods
    
    private func setup() {
        self.scrollView.refreshControl = UIRefreshControl()
        self.scrollView.refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        guard let rootTabBarController = self.tabBarController as? FURootTabBarController else {
            assertionFailure("tabBarController should not be nil and it should be of class FURootTabBarController")
            return
        }
        self.mibandController = rootTabBarController.mibandController
        assert(internalMibandController != nil, "internalMibadController should not be nil")
    }
    
    func reload(sender: UIRefreshControl?) {
        // device name
        internalMibandController.readDeviceName().subscribe(onNext: { [weak self] (deviceName) in
            DispatchQueue.main.async { self?.boundMiband.text = deviceName }
            }, onError: { (error) in
                debugPrint("Failed getting device info: \(error)")
        }).addDisposableTo(disposeBag)
        
        // battery info
        internalMibandController.readBatteryInfo().subscribe(onNext: { [weak self] (batteryInfo) in
            DispatchQueue.main.async {
                if let level = batteryInfo?.level {
                    self?.batteryLevel.text = "\(level)"
                }
                if let status = batteryInfo?.status {
                    self?.batteryStatus.text = "\(status)"
                }
            }
            }, onError: { (error) in
                debugPrint("Failed getting device info: \(error)")
        }).addDisposableTo(disposeBag)
        
        // realtime steps
//        internalMibandController
        
        sender?.endRefreshing()
    }
    
    
    func showPeripherals(_ peripherals: [RxBluetoothKit.ScannedPeripheral]) {
        let alert = UIAlertController(title: "Devices found", message: "Choose the device to pair with", preferredStyle: .actionSheet)
        for peripheral in peripherals {
            if let name = peripheral.advertisementData.localName {
                alert.addAction(
                    UIAlertAction(title: name, style: .default, handler: { [unowned self] (action) in
                        HUD.show(.label("Preparing mili services"))
                        self.mibandController.connect(peripheral).subscribe(
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
                            self.mibandController.readDeviceInfo().subscribe(onNext: { [unowned self] in
                                self.deviceInfo = $0
                                debugPrint("deviceInfo: \(self.deviceInfo)")
                                self.mibandController.setNotificationAndMonitorUpdates(characteristic: .notification)
                                    .subscribe(onNext: { [unowned self] in
                                        self.handleNotifications(from: $0)
                                        },
                                               onError: { debugPrint("\($0)")},
                                               onCompleted: { debugPrint("completed")},
                                               onDisposed: { debugPrint("disposed")}).addDisposableTo(self.disposeBag)
//                                let userInfo = FUUserInfo(uid: 1, gender: .female, age: 0, height: 0, weight: 0, type: .normal, alias: "")
//                                self.mibandController.writeUserInfo(userInfo, salt: self.deviceInfo!.salt).publish().connect().addDisposableTo(self.disposeBag)
                                self.mibandController.bindPeripheral().publish().connect().addDisposableTo(self.disposeBag)

                                
                                
                                self.mibandController.writeDateTime(Date()).publish().connect().addDisposableTo(self.disposeBag)   // sync current datatime
                                
                                
                                DispatchQueue.main.async {
//                                    self.vibrateBtn.isEnabled = true
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
    
    // MARK - IBActions
    @IBAction func scan(sender: UIButton) {
        debugPrint("\(#function) sender: \(sender)")
        var peripherals: [RxBluetoothKit.ScannedPeripheral] = []
        HUD.show(.labeledProgress(title: "Scanning", subtitle: "Looking for Mi bands" ))
        mibandController.scanMiBands().subscribe(onNext: { (peripheral) in
            peripherals.append(peripheral)
        }, onError: { (error) in
            DispatchQueue.main.async {
                self.present(FUMessageFactory.simpleMessageView(title: "Error", message: "\(error)"),
                             animated: true,
                             completion: nil)
            }
        }, onDisposed:  { [unowned self] in // mibandController is held by self
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

   
    
    @IBAction func vibrate(sender: Any) {
        mibandController.vibrate(alertLevel: .mildAlert, ledColorForMildAlert: FULEDColor(red: 6, green: 0, blue: 6))
    }

    @IBAction func pair(sender: Any) {
//        self.mibandController.bindPeripheral().publish().connect().addDisposableTo(self.disposeBag)
        let userInfo = FUUserInfo(uid: 1, gender: .female, age: 0, height: 0, weight: 0, type: .normal, alias: "")
        self.mibandController.writeUserInfo(userInfo, salt: self.deviceInfo!.salt).publish().connect().addDisposableTo(self.disposeBag)
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
                self.mibandController.vibrate(alertLevel: .mildAlert, ledColorForMildAlert: FULEDColor(red: 0, green: 5, blue: 6))
                break
            case .authFailed:
                self.mibandController.vibrate(alertLevel: .vibrateOnly)
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
