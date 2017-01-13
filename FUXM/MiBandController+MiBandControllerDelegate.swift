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
    func didConnectPeripheral(_ peripheral: CBPeripheral)
    func onMiBandsDiscovered(peripherals: [CBPeripheral])
    
    @objc optional func onDisconnected()
    @objc optional func onUpdateDeviceInfo(_ deviceInfo: FUDeviceInfo?, isNotifiying: Bool, error: Error?)
    @objc optional func onUpdateUserInfo(_ userInfo: FUUserInfo?, error: Error?)
}
