//
//  FUDashboardViewController.swift
//  FUXM
//
//  Created by Luis Wu on 1/21/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

import UIKit
import RxSwift

class FUDashboardViewController: UIViewController, FUTabBarChildViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var batteryLevel: UILabel!
    @IBOutlet var batteryStatus: UILabel!
    @IBOutlet var boundMiband: UILabel!
    @IBOutlet var realtimeSteps: UILabel!
    private var internalMibandController: MiBandController!
    private var disposeBag =  DisposeBag()
    
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

}
