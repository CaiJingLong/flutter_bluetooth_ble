//
//  CBService+findCBCharacteristic.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/3.
//

import CoreBluetooth

extension CBService{
    
    func findCharacteristic(id:String) -> CBCharacteristic?{
        if let chs = self.characteristics{
            for ch in chs {
                if ch.id == id{
                    return ch
                }
            }
            return nil
        }else{
            return nil
        }
    }
    
}
