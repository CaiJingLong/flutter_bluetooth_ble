//
//  BluetoothBle.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/11/29.
//

import Foundation
import CoreBluetooth

class Ble :NSObject, CBCentralManagerDelegate{
    
    static let shared = Ble()
    lazy var manager:CBCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    
    private override init(){
        super.init()
    }
    
    func initManager(){
        NSLog("init manager: \(manager.state)")
    }
    
    func isEnable() -> Bool{
        return manager.state == .poweredOn
    }
    
    func setEnable(enable: Bool){
        
    }
    
    var deviceMap = Dictionary<String, BluetoothWrapper>()
    
    func scanDevice(handler: ReplyHandler){
        checkState(handler: handler) {
            if #available(iOS 9.0, *) {
                if manager.isScanning{
                    manager.stopScan()
                }
            }
            let services = handler["services"] as? [String]
            let second = (handler["time"] ?? 3) as! Int
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(second), execute: {
                self.manager.stopScan()
                // 返回设备
                var result = [Dictionary<String,Any>]()
                for (_, wrapper) in self.deviceMap{
                    result.append(wrapper.toMap())
                }
                handler.success(any: ["devices": result])
            })
            var uuids = [CBUUID]()
            if services != nil {
                if let result = services?.map({ (value) -> CBUUID in
                    return CBUUID(string: value)
                }){
                    uuids.append(contentsOf: result)
                }
            }
            
            deviceMap.removeAll()
            connectionMap.removeAll()
            
            let deviceList = ConnectedDeviceManager.getConnectedDevice()
            for device in deviceList{
                onFoundDevice(peripheral: device.device , rssi: device.rssi)
            }
            
            manager.scanForPeripherals(withServices: uuids, options: nil)
        }
    }
    
    func checkState( handler: ReplyHandler ,_ runnable:()->Void){
        if manager.state != .poweredOn{
            handler.success(any: -1)
            return
        }
        runnable()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("更新状态: \(central.state.rawValue)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("扫描到设备, \(peripheral.name ?? "未知"), id = \(peripheral.identifier)")
        onFoundDevice(peripheral: peripheral, rssi: RSSI.intValue)
    }
    
    func onFoundDevice(peripheral: CBPeripheral, rssi: Int){
        if let _ = deviceMap[peripheral.id] {
            return
        } else {
            let device = BluetoothWrapper(device: peripheral, rssi: rssi)
            SwiftBluetoothBlePlugin.onFoundDevice(deviceWrapper: device)
            deviceMap[peripheral.id] = device
            connectionMap[peripheral.id] = BluetoothConnection(manager:manager, wrapper: device)
        }
    }
    
    var connectionMap = Dictionary<String, BluetoothConnection>()
    
    func findConnection(id:String)->BluetoothConnection?{
        return connectionMap[id]
    }
    
    
    func findConnection(peripheral: CBPeripheral)->BluetoothConnection?{
        return connectionMap[peripheral.id]
    }
    
    func findWrapper(id:String) -> BluetoothWrapper?{
        return deviceMap[id]
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("连接设备: \(peripheral.name ?? "未知")")
        if let wrapper = findWrapper(id: peripheral.id){
            ConnectedDeviceManager.addDevice(wrapper: wrapper)
        }
        findConnection(peripheral: peripheral)?.onConnect()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("连接设备失败: \(peripheral.name ?? "未知")")
        if let wrapper = findWrapper(id: peripheral.id){
            ConnectedDeviceManager.removeDevice(wrapper: wrapper)
        }
        findConnection(peripheral: peripheral)?.onFailConnect(error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("断开设备: \(peripheral.name ?? "未知")")
        if let wrapper = findWrapper(id: peripheral.id){
            ConnectedDeviceManager.removeDevice(wrapper: wrapper)
        }
        findConnection(peripheral: peripheral)?.onDisconnect(error: error)
    }
    
    var connectionHandler: ReplyHandler?
    
}
