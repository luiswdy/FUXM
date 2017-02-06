//
//  FURootTabBarController.swift
//  FUXM
//
//  Created by Luis Wu on 1/20/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import UIKit
import RxSwift
import RxBluetoothKit

protocol FUTabBarChildViewController {
    var mibandController: MiBandController { get set }
}

class FURootTabBarController: UITabBarController {
    let mibandController = MiBandController()
    let disposeBag = DisposeBag()
    
    // MARK - initializers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    // MARK - intial setup
    private func setup() {
        mibandController.btState.subscribe(onNext: { (state) in
        switch state {
        case .poweredOn:
            debugPrint("Bluetooth powered on. ReadyretrievePeripheral.")
            break
        default:
            debugPrint("Bluetooth not powered on. State; \(state)")
            break
        }
        }, onError: { (error) in
            debugPrint("")
        }, onCompleted: { 
            debugPrint("Got completed")
        }, onDisposed: {
            debugPrint("Got disposed")
        }).addDisposableTo(disposeBag)
        
        if let storedUUID = MiBandUserDefaults.loadBoundPeripheralUUID() {
            mibandController.retrievePeripheral(withUUID: storedUUID).subscribe(onNext: { [weak self] (peripheral) in
                if let peripheral = peripheral, let disposeBag = self?.disposeBag {
                    self?.mibandController.connect(peripheral).subscribe(onError: { (error) in
                        debugPrint("Failed connecting peripheral \(peripheral): \(error)")
                    }, onCompleted: { [weak self] in
                        self?.mibandController.areCharacteristicsReady.value  = true
                        self?.setupMiband()
                    }).addDisposableTo(disposeBag)
                }
            }, onError: { (error) in
                debugPrint("Failed retrieving peripheral: \(error)")
            }, onCompleted: { 
                debugPrint("Retrieving peripheral completed")
            }, onDisposed: { 
                debugPrint("Disposed")
            }).addDisposableTo(disposeBag)
        }
    }
    
    private func setupMiband() {
        mibandController.readDeviceInfo().subscribe(onNext: { [unowned self] in
            debugPrint("deviceInfo: \($0)")
            self.mibandController.setNotificationAndMonitorUpdates(characteristic: .notification)
                .subscribe(onNext: { [unowned self] in self.handleNotifications(from: $0) },
                           onError: { debugPrint("\($0)")},
                           onCompleted: { debugPrint("completed")},
                           onDisposed: { debugPrint("disposed")}).addDisposableTo(self.disposeBag)
            let userInfo = FUUserInfo(uid: 1, gender: .male, age: 37, height: 170, weight: 63, type: .normal, alias: "Luis Wu") // TODO: get user info somewhere instead of hard-coded
            if let salt = $0?.salt {
                self.mibandController.writeUserInfo(userInfo, salt: salt).publish().connect().addDisposableTo(self.disposeBag)
            } else {
                assertionFailure("cannot get salt")
            }
            self.mibandController.bindPeripheral().publish().connect().addDisposableTo(self.disposeBag)
            self.mibandController.writeDateTime(Date()).publish().connect().addDisposableTo(self.disposeBag)   // sync current datatime
        }).addDisposableTo(self.disposeBag)
    }
    
    private func injectMibandController() {
        for child in childViewControllers {
            assert(child.isKind(of: UINavigationController.self), "Expected getting UINavigationController")
            if var tabBarChild = child.childViewControllers.first as? FUTabBarChildViewController {
                debugPrint("Conform FUTabBarChildViewController")
                tabBarChild.mibandController = mibandController
            } else {
                debugPrint("Doesn't conform FUTabBarChildViewController")
            }
        }
    }
    
    // TODO: Maybe define protocol to decouple the dependency of RxBluetooth while using MiBandController
    private func handleNotifications(from characteristic: Characteristic) {
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
    
    // MARK - Life cycle
    override func viewDidLoad() {
        injectMibandController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
}
