//
//  MiBandUserDefaults.swift
//  FUXM
//
//  Created by Luis Wu on 1/12/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//
import Foundation

// Keys for accessing 
enum FUUserDefaultKeys {
    case boundPeripheral
}

class MiBandUserDefaults {
    static func loadBoundPeripheralUUID() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: "\(FUUserDefaultKeys.boundPeripheral)") else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    static func storeBoundPeripheralUUID(_ uuid: UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey: "\(FUUserDefaultKeys.boundPeripheral)")
    }
    
}
