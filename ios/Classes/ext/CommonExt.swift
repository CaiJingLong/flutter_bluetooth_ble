//
//  CommonExt.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/3.
//

import CoreBluetooth
import Foundation

protocol IdAble {
    var id: String
    { get }
}

extension CBPeripheral: IdAble {
    var id: String {
        return identifier.uuidString
    }
}

extension CBService: IdAble {
    var id: String {
        return uuid.uuidString
    }
}

extension CBCharacteristic: IdAble {
    var id: String {
        return uuid.uuidString
    }
}