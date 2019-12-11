//
//  BluetoothWrapper.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/11/29.
//

import Foundation
import CoreBluetooth

class BluetoothWrapper{
    var device: CBPeripheral
    var rssi:Int
    
    var name:String?
    
    var id: String {
        return device.id
    }
    
    init(device:CBPeripheral, name:String?, rssi:Int) {
        self.device = device
        self.name = name
        self.rssi = rssi
    }
    
    func toMap() -> Dictionary<String, Any>{
        return [
            "id": id,
            "rssi" : rssi,
            "name": name ?? device.name ?? ""
        ]
    }
}
