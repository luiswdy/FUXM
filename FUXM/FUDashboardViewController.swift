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
    @IBOutlet var batteryPercentage: UILabel!
    @IBOutlet var boundPeripheral: UILabel!
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
    }
    
    func refresh(_ sender: UIRefreshControl) {
        debugPrint("refreshing")
        sender.endRefreshing()
    }
    
    // MARK - private methods
    
    private func setup() {
//        self.scrollView.refreshControl = UIRefreshControl()
//        self.scrollView.refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
//        guard let rootTabBarController = self.tabBarController as? FURootTabBarController else {
//            assertionFailure("tabBarController should not be nil and it should be of class FURootTabBarController")
//            return
//        }
//        self.mibandController = rootTabBarController.mibandController
        assert(internalMibandController != nil, "internalMibadController should not be nil")
        
        // device name
        
        internalMibandController.readDeviceName().subscribe(onNext: { [weak self] (deviceName) in
            DispatchQueue.main.async { self?.boundPeripheral.text = deviceName }
            }, onError: { (error) in
                debugPrint("Failed getting device info: \(error)")
        }).addDisposableTo(disposeBag)
        
        // battery info
        internalMibandController.readBatteryInfo().subscribe(onNext: { [weak self] (batteryInfo) in
            DispatchQueue.main.async {
                self?.batteryPercentage.text = "\(batteryInfo?.level)"
            }
            }, onError: { (error) in
                debugPrint("Failed getting device info: \(error)")
        }).addDisposableTo(disposeBag)
    }
    
    func reload() {
    }

}
