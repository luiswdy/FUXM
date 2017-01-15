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
    @objc optional func onUpdateDeviceInfo(_ deviceInfo: FUDeviceInfo?, isNotifying: Bool, error: Error?)
    @objc optional func onUpdateUserInfo(_ userInfo: FUUserInfo?, error: Error?)
    @objc optional func onUpdateBatteryInfo(_ batteryInfo: FUBatteryInfo?, isNotifying: Bool, error: Error?)
    @objc optional func onUpdateLEParams(_ leParams: FULEParams?, isNotifying: Bool, error: Error?)
    @objc optional func onUpdateDateTime(_ dateTime: FUDateTime?, error: Error?)
    @objc optional func onUpdateSensorData(_ sensorData: FUSensorData?, isNotifying: Bool, error: Error?)
}
