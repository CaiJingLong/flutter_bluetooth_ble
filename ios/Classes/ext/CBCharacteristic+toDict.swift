//
//  CBCharacteristic+toDict.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/3.
//

import CoreBluetooth

extension CBCharacteristic {
    func toMap() -> [String: Any] {
        let chMap: [String: Any] = [
            "uuid": self.id,
            "write": self.writeable,
            "writeableWithoutResponse": self.writeableWithoutResponse,
            "readable": self.readable,
            "notifiable": self.notifiable,
            "notifying": self.isNotifying,
            "serviceId": self.getCBService()?.id ?? "",
        ]

        return chMap
    }
}

extension CBCharacteristic{
    
    func getCBService() -> CBService? {
        let service: CBService? = self.service
        return service
    }

}
