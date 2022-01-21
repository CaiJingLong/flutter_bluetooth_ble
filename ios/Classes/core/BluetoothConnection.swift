//
//  BluetoothConnection.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/12/2.
//

import CoreBluetooth
import Flutter

class BluetoothConnection: NSObject {
    var wrapper: BluetoothWrapper!
    var manager: CBCentralManager!

    var channel: FlutterMethodChannel!

    var peripheral: CBPeripheral {
        return wrapper.device
    }

    init(manager: CBCentralManager, wrapper: BluetoothWrapper) {
        super.init()
        self.manager = manager
        self.wrapper = wrapper
        channel = FlutterMethodChannel(name: "top.kikt/ble/\(wrapper.id)", binaryMessenger: SwiftBluetoothBlePlugin.registrar.messenger())
        channel.setMethodCallHandler { call, result in
            self.onMethodCall(call: call, result: result)
        }
        peripheral.delegate = self
    }

    func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let handler = ReplyHandler(call: call, result: result)
        switch call.method {
        case "connect":
            connect()
        case "disconnect":
            disconnect()
        case "discoverServices":
            discoverService(handler)
        case "discoverCharacteristics":
            discoverCharacteristics(handler)
        case "writeData":
            writeData(handler)
        case "requestMtu":
            handler.success(any: peripheral.maximumWriteValueLength(for: .withoutResponse))
        case "changeNotify":
            let chId = handler["ch"] as! String
            let serviceId = handler["service"] as! String
            let notify = handler["notify"] as! Bool
            changeNotify(serviceId: serviceId, chId: chId, notify: notify)
            handler.success(any: 1)
        default:
            handler.notImplemented()
        }
    }

    func onConnect() {
        invokeMethod("onConnect")
    }

    func onFailConnect(error _: Error?) {
        invokeMethod("connectFail")
    }

    func onDisconnect(error _: Error?) {
        invokeMethod("onDisconnect")
    }

    func invokeMethod(_ method: String, _ args: Any? = nil) {
        channel.invokeMethod(method, arguments: args)
    }

    func connect() {
        manager.connect(wrapper.device, options: nil)
    }

    func disconnect() {
        manager.cancelPeripheralConnection(wrapper.device)
    }

    var serviceHandler: ReplyHandler?

    func discoverService(_ handler: ReplyHandler) {
        serviceHandler = handler
        peripheral.discoverServices(nil)
    }

    // key 是 service的uuid, value是回复
    var chHandlerMap = [String: ReplyHandler]()

    func findService(uuid: String) -> CBService? {
        if peripheral.services == nil {
            return nil
        }
        for service in peripheral.services! {
            if service.id == uuid {
                return service
            }
        }
        return nil
    }

    func discoverCharacteristics(_ handler: ReplyHandler) {
        let uuid = handler["service"] as! String
        if let service = findService(uuid: uuid) {
            chHandlerMap[uuid] = handler
            peripheral.discoverCharacteristics(nil, for: service)
        } else {
            handler.success(any: nil)
        }
    }
}

extension BluetoothConnection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        guard let services = peripheral.services else {
            serviceHandler?.success(any: [String]())
            serviceHandler = nil
            return
        }
        let result = services.map { (service) -> String in
            service.id
        }
        serviceHandler?.success(any: result)
        serviceHandler = nil
    }

    func peripheral(_: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
        let handler = chHandlerMap[service.id]
        var result = [[String: Any]]()

        if let chs = service.characteristics {
            for ch in chs {
                result.append(ch.toMap())
            }
        }

        handler?.success(any: result)
        chHandlerMap.removeValue(forKey: service.id)
    }

    func changeNotify(serviceId: String, chId: String, notify: Bool) {
        guard let service = findService(uuid: serviceId), let ch = service.findCharacteristic(id: chId) else {
            return
        }

        if ch.isNotifying == notify {
            return
        }

        peripheral.setNotifyValue(notify, for: ch)
    }

    func peripheral(_: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error _: Error?) {
        invokeMethod("notifyState", [
            "ch": characteristic.toMap(),
            "serviceId": characteristic.getCBService()?.id ?? "",
        ])
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
        invokeMethod("notifyValue", [
            "ch": characteristic.toMap(),
            "serviceId": characteristic.getCBService()?.id ?? "",
            "data": characteristic.value ?? Data(),
        ])
    }
}

extension BluetoothConnection {
    func writeData(_ replyHandler: ReplyHandler) {
        let data = replyHandler.getData(key: "data")
        let serviceId = replyHandler["service"] as! String
        let chId = replyHandler["ch"] as! String

        guard let service = findService(uuid: serviceId), let ch = service.findCharacteristic(id: chId) else {
            replyHandler.success(any: -1)
            return
        }

        peripheral.writeValue(data, for: ch, type: .withoutResponse)
        replyHandler.success(any: 1)
    }
}
