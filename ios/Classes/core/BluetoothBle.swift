//
//  BluetoothBle.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/11/29.
//

import CoreBluetooth
import Foundation

class Ble: NSObject, CBCentralManagerDelegate {
    static let shared = Ble()
    lazy var manager: CBCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)

    private override init() {
        super.init()
    }

    func initManager() {
        NSLog("init manager: \(manager.state)")
    }

    func isEnable() -> Bool {
        return manager.state == .poweredOn
    }

    func setEnable(enable _: Bool) {}

    var deviceMap = [String: BluetoothWrapper]()

    func supportBle() -> Bool {
        return manager.state != .unsupported
    }

    func scanDevice(handler: ReplyHandler) {
        checkState(handler: handler) {
            if #available(iOS 9.0, *) {
                if manager.isScanning {
                    manager.stopScan()
                }
            }
            let services = handler["services"] as? [String]
            let second = (handler["time"] ?? 3) as! Int
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(second)) {
                self.manager.stopScan()
                // 返回设备
                var result = [[String: Any]]()
                for (_, wrapper) in self.deviceMap {
                    result.append(wrapper.toMap())
                }
                handler.success(any: ["devices": result])
            }
            var uuids = [CBUUID]()
            if services != nil {
                if let result = services?.map({ (value) -> CBUUID in
                    CBUUID(string: value)
                }) {
                    uuids.append(contentsOf: result)
                }
            }

            deviceMap.removeAll()
            connectionMap.removeAll()

            let deviceList = ConnectedDeviceManager.getConnectedDevice()
            for device in deviceList {
                onFoundDevice(peripheral: device.device, localName: device.name, rssi: device.rssi)
            }

            NSLog("uuids = \(uuids)")

            manager.scanForPeripherals(withServices: uuids, options: nil)
        }
    }

    func checkState(handler: ReplyHandler, _ runnable: () -> Void) {
        if manager.state != .poweredOn {
            handler.success(any: -1)
            return
        }
        runnable()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("更新状态: \(central.state.rawValue)")
    }

    func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String

        let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey]

        NSLog("扫描到设备, \(localName ?? peripheral.name ?? "未知"), id = \(peripheral.identifier)")

        onFoundDevice(peripheral: peripheral, localName: localName, rssi: RSSI.intValue)
    }

    func onFoundDevice(peripheral: CBPeripheral, localName: String?, rssi: Int) {
        if let _ = deviceMap[peripheral.id] {
            return
        } else {
            let device = BluetoothWrapper(device: peripheral, name: localName, rssi: rssi)
            SwiftBluetoothBlePlugin.onFoundDevice(deviceWrapper: device)
            deviceMap[peripheral.id] = device
            connectionMap[peripheral.id] = BluetoothConnection(manager: manager, wrapper: device)
        }
    }

    var connectionMap = [String: BluetoothConnection]()

    func findConnection(id: String) -> BluetoothConnection? {
        return connectionMap[id]
    }

    func findConnection(peripheral: CBPeripheral) -> BluetoothConnection? {
        return connectionMap[peripheral.id]
    }

    func findWrapper(id: String) -> BluetoothWrapper? {
        return deviceMap[id]
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("连接设备: \(peripheral.name ?? "未知")")
        if let wrapper = findWrapper(id: peripheral.id) {
            ConnectedDeviceManager.addDevice(wrapper: wrapper)
        }
        findConnection(peripheral: peripheral)?.onConnect()
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("连接设备失败: \(peripheral.name ?? "未知")")
        if let wrapper = findWrapper(id: peripheral.id) {
            ConnectedDeviceManager.removeDevice(wrapper: wrapper)
        }
        findConnection(peripheral: peripheral)?.onFailConnect(error: error)
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("断开设备: \(peripheral.name ?? "未知")")
        if let wrapper = findWrapper(id: peripheral.id) {
            ConnectedDeviceManager.removeDevice(wrapper: wrapper)
        }
        findConnection(peripheral: peripheral)?.onDisconnect(error: error)
    }

    var connectionHandler: ReplyHandler?
}