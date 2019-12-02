import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BleDevice with ChangeNotifier implements Comparable<BleDevice> {
  String id;
  int rssi;
  String name;

  List<String> service = [];

  bool _isConnect = false;

  bool get isConnect => _isConnect;

  set isConnect(bool isConnect) {
    _isConnect = isConnect;
    notifyListeners();
  }

  MethodChannel _channel;

  static BleDevice fromMap(Map map) {
    return BleDevice()
      ..id = map["id"]
      ..name = map["name"]
      ..rssi = map["rssi"]
      ..refreshChannel();
  }

  void refreshChannel() {
    _channel = MethodChannel("top.kikt/ble/$id");
    _channel.setMethodCallHandler(this._onCall);
  }

  @override
  int compareTo(BleDevice other) {
    if (name.isEmpty) {
      return 1;
    }
    if (other.name.isEmpty) {
      return -1;
    }
    return this.name.compareTo(other.name);
  }

  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case "onConnect":
        onConnect();
        break;
      case "onDisconnect":
        onDisconnect();
        break;
      case "connectFail":
        connectFail();
        break;
      case "onDiscoverServices":
        onDiscoverServices(call);
        break;
    }
  }

  void connect() {
    _channel.invokeMethod("connect");
  }

  void disconnect() {
    _channel.invokeMethod("disconnect");
  }

  @override
  String toString() {
    return 'BleDevice: {"name": $name, "id": $id, "rssi":$rssi}';
  }

  void onConnect() {
    isConnect = true;
  }

  void onDisconnect() {
    isConnect = false;
  }

  void connectFail() {
    isConnect = false;
  }

  Future<void> discoverServices() async {
    this.service.clear();
    await _channel.invokeMethod("discoverServices");
  }

  void onDiscoverServices(MethodCall call) {
    final List args = call.arguments;
    print("找到service: $args");
    args.sort();
    this.service.addAll(args.cast());
    notifyListeners();
  }

  Future<void> discoverCharacteristics(String service) async {
    await _channel.invokeMethod("discoverCharacteristics", {
      "services": service,
    });
  }
}
