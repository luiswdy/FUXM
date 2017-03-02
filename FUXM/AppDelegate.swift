//
//  AppDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 12/7/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import UIKit
import CallKit
import RxBluetoothKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CXCallObserverDelegate {

    var window: UIWindow?
    let callObserver = CXCallObserver()
    
//    let disposeBag = DisposeBag()
//    let mibandController = MiBandController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        
        
//        mibandController.listenOnRestoreState().subscribe(onNext: { [weak self] (restoredState) in
//            if let strongSelf = self, let peripheral = restoredState.peripherals.first {
//                strongSelf.mibandController.connect(peripheral).publish().connect().addDisposableTo(strongSelf.disposeBag)  // TODO subscribe next complete error ..etc
//            }
//            }, onError: { (error) in
//                debugPrint("listen to retored state failed: \(error)")
//        }, onCompleted: {
//            debugPrint("\(#function) completed")
//        }, onDisposed: {
//            debugPrint("disposed")
//        }).addDisposableTo(self.disposeBag)
        
        // TEST
        callObserver.setDelegate(self, queue: nil)
        
        // END TEST
        
        
        return true
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    // MARK - CXCallObserverDelegate
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        debugPrint("1. \(call.hasConnected)")
        debugPrint("2. \(call.hasEnded)")
        debugPrint("3. \(call.isOnHold)")
        debugPrint("4. \(call.isOutgoing)")
        debugPrint("5. \(call.uuid)")
        debugPrint("6. \(callObserver.calls)")
        
        if (call.hasConnected) {
            debugPrint("hasConnected")
        } else {
            debugPrint("!hasConnected")
        }
    }

}

