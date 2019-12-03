//
//  BluetoothWrapper.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/11/29.
//

import Foundation
import CoreBluetooth

struct BluetoothWrapper{
    var device: CBPeripheral
    var rssi:Int
    
    var id: String {
        return device.id
    }
    
    func toMap() -> Dictionary<String, Any>{
        return [
            "id": id,
            "rssi" : rssi,
            "name": device.name ?? ""
        ]
    }
}
