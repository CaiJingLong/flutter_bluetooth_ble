//
//  CBCharacteristicProperties+LightBlue.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/3.
//

import CoreBluetooth

extension CBCharacteristicProperties {
    public var containsProperties: [String] {
        var resultProperties = [String]()
        if contains(.broadcast) {
            resultProperties.append("Broadcast")
        }
        if contains(.read) {
            resultProperties.append("Read")
        }
        if contains(.write) {
            resultProperties.append("Write")
        }
        if contains(.writeWithoutResponse) {
            resultProperties.append("Write Without Response")
        }
        if contains(.notify) {
            resultProperties.append("Notify")
        }
        if contains(.indicate) {
            resultProperties.append("Indicate")
        }
        if contains(.authenticatedSignedWrites) {
            resultProperties.append("Authenticated Signed Writes")
        }
        if contains(.extendedProperties) {
            resultProperties.append("Extended Properties")
        }
        if contains(.notifyEncryptionRequired) {
            resultProperties.append("Notify Encryption Required")
        }
        if contains(.indicateEncryptionRequired) {
            resultProperties.append("Indicate Encryption Required")
        }
        return resultProperties
    }
    
}

extension CBCharacteristic{
    
    var readable:Bool{
        return properties.contains(.read)
    }
    
    var writeable:Bool{
        return properties.contains(.write)
    }
    
    var writeableWithoutResponse: Bool{
        return properties.contains(.writeWithoutResponse)
    }
    
    var notifyable: Bool{
        return properties.contains(.notify)
    }
    
}
