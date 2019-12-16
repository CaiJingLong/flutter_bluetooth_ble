import 'dart:async';

import 'src/ble_device.dart';
import 'package:flutter/services.dart';
export 'src/ble_device.dart';
export 'src/ble_ch.dart';
export 'src/ble_service.dart';
export 'src/ble_notify_data.dart';

class BluetoothBle {
  static const MethodChannel _channel = const MethodChannel('bluetooth_ble');

  static BluetoothBle _instance;

  BluetoothBle._() {
    _channel.invokeMethod("init");
    _channel.setMethodCallHandler(this._onCallback);
  }

  factory BluetoothBle() {
    _instance ??= BluetoothBle._();
    return _instance;
  }

  final devices = <BleDevice>[];

  /// timeout, second
  Future<List<BleDevice>> scan({
    List<String> services,
    int timeout = 3,
  }) async {
    this.devices.clear();
    _findDeviceController.add(null);
    final result = await _channel.invokeMethod("scan", {
      "services": services,
      "time": timeout,
    });
    final list = result["devices"];
    print("on scan return result!");
    if (list == null || list.isEmpty) {
      notifyDeviceChange();
      return this.devices;
    }
    for (final map in list) {
      final device = BleDevice.fromMap(map);
      _addDevice(device);
    }
    this.devices.sort();
    return this.devices;
  }

  StreamController<BleDevice> _findDeviceController =
      StreamController.broadcast();

  Stream<BleDevice> get deviceStream => _findDeviceController.stream;

  void _addDevice(BleDevice device) {
    if (device == null) {
      notifyDeviceChange();
      return;
    }
    if (!devices.any((test) => test.id == device.id)) {
      devices.add(device);
      devices.sort();
      _findDeviceController.add(device);
    }
  }

  void notifyDeviceChange() {
    _findDeviceController.add(null);
  }

  Future _onCallback(MethodCall call) async {
    switch (call.method) {
      case "found_device":
        final device = BleDevice.fromMap(call.arguments);
        _addDevice(device);
        break;
    }
  }

  Future<bool> supportBle() async {
    return _channel.invokeMethod("supportBle");
  }

  /// 蓝牙开关是否开启
  Future<bool> isEnabled() async {
    return _channel.invokeMethod("isEnabled");
  }
}
