//
//  MiBandController+MiBandControllerDelegate.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation
import CoreBluetooth.CBPeripheral

@objc protocol MiBandControllerDelegate {
    func onConnected()
    func onMiBandsDiscovered(peripherals: [CBPeripheral])
    
    @objc optional func onDisconnected()
    @objc optional func onUpdateDeviceInfo(deviceInfo: FUDeviceInfo?, isNotifiying: Bool, error: Error?)
}
