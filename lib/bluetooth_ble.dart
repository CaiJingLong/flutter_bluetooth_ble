import 'dart:async';

import 'src/ble_device.dart';
import 'package:flutter/services.dart';
export 'src/ble_device.dart';
export 'src/ble_ch.dart';

class BluetoothBle {
  static const MethodChannel _channel = const MethodChannel('bluetooth_ble');

  static BluetoothBle _instance;

  BluetoothBle._() {
    _channel.invokeMethod("init");
  }

  factory BluetoothBle() {
    _instance ??= BluetoothBle._();
    return _instance;
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// timeout, second
  Future<List<BleDevice>> scan({
    List<String> services,
    int timeout = 3,
  }) async {
    final result = await _channel.invokeMethod("scan", {
      "services": services,
      "time": timeout,
    });
    print("result = $result");
    final list = result["devices"];
    final devices = List<BleDevice>();
    for (final map in list) {
      final device = BleDevice.fromMap(map);
      devices.add(device);
    }
    devices.sort();
    return devices;
  }

  Future<void> connect(BleDevice bleDevice) async {
    final result = await _channel.invokeMethod("connect", {
      "id": bleDevice.id,
    });
    print("connect result = $result");
  }
}
