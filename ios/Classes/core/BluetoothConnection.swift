//
//  BluetoothConnection.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/2.
//

import Flutter
import CoreBluetooth

class BluetoothConnection: NSObject {
    
    var wrapper: BluetoothWrapper!
    var manager: CBCentralManager!
    
    var channel:FlutterMethodChannel!
    
    var peripheral : CBPeripheral {
        return wrapper.device
    }
    
    init(manager: CBCentralManager,wrapper: BluetoothWrapper){
        super.init()
        self.manager = manager
        self.wrapper = wrapper
        self.channel = FlutterMethodChannel(name: "top.kikt/ble/\(wrapper.id)", binaryMessenger: SwiftBluetoothBlePlugin.registrar.messenger())
        self.channel.setMethodCallHandler { (call, result) in
            self.onMethodCall(call: call, result: result)
        }
        self.peripheral.delegate = self
    }
    
    func onMethodCall(call: FlutterMethodCall, result:@escaping FlutterResult){
        let handler = ReplyHandler(call: call, result: result)
        switch call.method {
        case "connect":
            connect()
            break;
        case "disconnect":
            disconnect()
            break
        case "discoverServices":
            discoverService(handler)
            break
        case "discoverCharacteristics":
            discoverCharacteristics(handler)
            break
        default:
            handler.notImplemented()
        }
    }
    
    func onConnect(){
       invokeMethod("onConnect")
    }
    
    func onFailConnect(error:Error?){
        invokeMethod("connectFail")
    }
    
    func onDisconnect(error:Error?){
        invokeMethod("onDisconnect")
    }
    
    func invokeMethod(_ method:String, _ args:Any? = nil){
        channel.invokeMethod(method, arguments: args)
    }
    
    func connect(){
        manager.connect(wrapper.device, options: nil)
    }
    
    func disconnect(){
        manager.cancelPeripheralConnection(wrapper.device)
    }
    
//    var serviceHandler: ReplyHandler? = nil
    
    func discoverService(_ handler: ReplyHandler){
//        serviceHandler = handler
        peripheral.discoverServices(nil)
    }
    
    // key 是 service的uuid, value是回复
    var chHandlerMap = Dictionary<String,ReplyHandler>()
    
    func findService(uuid:String) -> CBService?{
        if peripheral.services == nil{
            return nil
        }
        for service in peripheral.services!{
            if service.uuid.uuidString == uuid{
                return service
            }
        }
        return nil
    }
    
    func discoverCharacteristics(_ handler: ReplyHandler){
        let uuid = handler["service"] as! String
        if let service = findService(uuid: uuid){
            chHandlerMap[uuid] = handler
            peripheral.discoverCharacteristics(nil, for: service)
        } else {
            handler.success(any: nil)
        }
    }
}

extension BluetoothConnection: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
//            serviceHandler?.result(nil)
            return
        }
        let result = services.map { (service) -> String in
            return service.uuid.uuidString
        }
        invokeMethod("onDiscoverServices", result)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let handler = chHandlerMap[service.uuid.uuidString]
        var result = [Dictionary<String,Any>]();
        
        if let chs = service.characteristics{
            for ch in chs {
                // 继续传递数据到dart层
                let chMap = [
                    "notifying": ch.isNotifying,
                    
                ]
                result.append(chMap)
            }
        }
        
        handler?.success(any: result)
    }
}
