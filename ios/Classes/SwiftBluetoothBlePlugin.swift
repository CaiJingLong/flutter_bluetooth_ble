import Flutter
import UIKit

public class SwiftBluetoothBlePlugin: NSObject, FlutterPlugin {
    
    static var registrar: FlutterPluginRegistrar!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bluetooth_ble", binaryMessenger: registrar.messenger())
        let instance = SwiftBluetoothBlePlugin()
        self.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    let ble = Ble.shared;
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let handler = ReplyHandler(call: call, result: result)
        switch call.method{
        case "scan":
            ble.scanDevice(handler: handler)
            break
        case "init":
            ble.initManager()
            break
        default:
            handler.notImplemented()
        }
    }
}
