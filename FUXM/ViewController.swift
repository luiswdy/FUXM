//
//  ViewController.swift
//  FUXM
//
//  Created by Luis Wu on 12/7/16.
//  Copyright © 2016 Luis Wu. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, MiBand1ControllerDelegate {
    
//    var discorevedPeripherals = Set<CBPeripheral>()
    var miBandControl: MiBand1Controller?
//
//    var pairedPeripheral: CBPeripheral?
    
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var stopScanBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any ad ditional setup after loading the view, typically from a nib.
        miBandControl = MiBand1Controller(self)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scan() {
        if let miBandControl = miBandControl {
            if miBandControl.state == .poweredOn {
                miBandControl.scan()
            }
        }
    }
    
    @IBAction func stopScan() {
        miBandControl?.stopScan()
    }


    // MiBand1ControllerDelegate
    

}

