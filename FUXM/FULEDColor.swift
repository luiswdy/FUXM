//
//  FULEDColor.swift
//  FUXM
//
//  Created by Luis Wu on 1/18/17.
//  Copyright © 2017 Luis Wu. All rights reserved.
//

class FULEDColor {
    private static let minValue: UInt8 = 0
    private static let maxValue: UInt8 = 6
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    
    required init?(red: UInt8, green: UInt8, blue: UInt8) {    // failable initializer
        if !(FULEDColor.minValue ... FULEDColor.maxValue ~= red) ||         // check if rgb are within the range
           !(FULEDColor.minValue ... FULEDColor.maxValue ~= green) ||
           !(FULEDColor.minValue ... FULEDColor.maxValue ~= blue) {
            return nil
        } else {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
    
    static func redColor() -> FULEDColor {
        return FULEDColor(red: 6, green: 0, blue: 0)!
    }
    
    static func blueColor() -> FULEDColor {
        return FULEDColor(red: 0, green: 0, blue: 6)!
    }
    
    static func greenColor() -> FULEDColor {
        return FULEDColor(red: 0, green: 6, blue: 0)!
    }
    
    static func purpleColor() -> FULEDColor {
        return FULEDColor(red: 6, green: 0, blue: 6)!
    }
    
    static func yellowColor() -> FULEDColor {
        return FULEDColor(red: 6, green: 6, blue: 0)!
    }
    
    static func cyanColor() -> FULEDColor {
        return FULEDColor(red: 0, green: 6, blue: 6)!
    }
}
