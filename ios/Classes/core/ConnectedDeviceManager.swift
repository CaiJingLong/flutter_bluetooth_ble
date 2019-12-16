//
//  ConnectedDeviceManager.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/10.
//

import CoreBluetooth

class ConnectedDeviceManager {
    private static var deviceMap = [String: BluetoothWrapper]()

    static func addDevice(wrapper: BluetoothWrapper) {
        if let _ = deviceMap[wrapper.id] {
            return
        } else {
            deviceMap[wrapper.id] = wrapper
        }
    }

    static func removeDevice(wrapper: BluetoothWrapper) {
        deviceMap.removeValue(forKey: wrapper.id)
    }

    static func getConnectedDevice() -> [BluetoothWrapper] {
        return deviceMap.map { (_, value) -> BluetoothWrapper in
            value
        }
    }
}