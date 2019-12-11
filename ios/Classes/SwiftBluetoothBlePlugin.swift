import Flutter
import UIKit

public class SwiftBluetoothBlePlugin: NSObject, FlutterPlugin {
    
    static var registrar: FlutterPluginRegistrar!
    
    static var channel: FlutterMethodChannel!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "bluetooth_ble", binaryMessenger: registrar.messenger())
        let instance = SwiftBluetoothBlePlugin()
        self.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private static func invoke(method: String, args: Any?) {
        channel.invokeMethod(method, arguments: args)
    }
    
    static func onFoundDevice(deviceWrapper: BluetoothWrapper){
        invoke(method: "found_device", args: deviceWrapper.toMap())
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
        case "isEnabled":
            handler.success(any: ble.isEnable())
            break
        default:
            handler.notImplemented()
        }
    }
    
}
