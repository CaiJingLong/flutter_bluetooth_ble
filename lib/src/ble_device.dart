import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ble_ch.dart';
import 'ble_notify_data.dart';
import 'ble_service.dart';

class BleDevice with ChangeNotifier implements Comparable<BleDevice> {
  StreamController<BleNotifyData> _notifyDataCtl = StreamController.broadcast();

  Stream<BleNotifyData> get notifyDataStream => _notifyDataCtl.stream;

  String id;
  int rssi;
  String name;

  List<BleService> service = [];

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

  @override
  void dispose() {
    _notifyDataCtl.close();
    super.dispose();
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
      case "notifyState":
        onNotifyStateChange(call.arguments);
        break;
      case "notifyValue":
        notifyGetValue(call.arguments);
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
    this.service.clear();
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
    final services = args.map((v) => BleService(this, v));
    this.service.clear();
    this.service.addAll(services);
    notifyListeners();
  }

  Future<List<BleCh>> discoverCharacteristics(BleService service) async {
    final List characteristics =
        await _channel.invokeMethod("discoverCharacteristics", {
      "service": service.id,
    });

    final result = <BleCh>[];

    for (final map in characteristics) {
      result.add(BleCh.fromMap(map, service: service));
    }

    service.resetCh(result);

    return result;
  }

  Future<void> writeData({
    @required BleCh ch,
    @required Uint8List data,
    Duration everyDelay = const Duration(milliseconds: 30),
  }) async {
    if (!ch.writeNoResponse) {
      print("不能写数据");
      return;
    }

    // 如果数据大于20字节, 需要拆开发送
    if (data.length <= 20) {
      await _writeData(ch: ch, data: data);
    } else {
      var count = data.length ~/ 20;

      final remainder = data.length % 20;
      if (remainder > 0) {
        count++;
      }

      print("长度 : ${data.length} 字节, 需要拆成$count个");

      for (var i = 0; i < count; i++) {
        final start = i * 20;
        int end;
        if (remainder > 0 && i == count - 1) {
          end = start + remainder;
        } else {
          end = start + 20;
        }
        await _writeData(
          ch: ch,
          data: data.sublist(start, end),
        );
        if (i != count - 1) {
          await Future.delayed(everyDelay);
        }
      }
    }
  }

  Future<void> _writeData(
      {@required BleCh ch, @required Uint8List data}) async {
    await _channel.invokeMethod("writeData", {
      "service": ch.service.id,
      "data": data,
      "ch": ch.id,
    });
  }

  void changeNotify(BleCh ch, {bool notify}) async {
    if (notify == null) {
      notify = !ch.notifying;
    }
    await _channel.invokeMethod(
      "changeNotify",
      {
        "ch": ch.id,
        "service": ch.service.id,
        "notify": notify,
      },
    );
  }

  void onNotifyStateChange(arguments) {
    final service = findServiceById(arguments["serviceId"]);
    final ch = BleCh.fromMap(arguments["ch"], service: service);
    service.updateCh(ch);
    notifyListeners();
  }

  BleService findServiceById(String id) {
    if (service == null || service.isEmpty) {
      return null;
    }
    return service.firstWhere((v) => v.id == id, orElse: () => null);
  }

  Future<BleCh> findCh(String serviceId, String chId) async {
    BleService service = findServiceById(id);
    if (service == null) {
      await discoverServices();
      service = findServiceById(id);
    }

    if (service == null) {
      return null;
    }
    await discoverCharacteristics(service);
    return service.findCh(chId);
  }

  @override
  bool operator ==(other) {
    if (other == null) {
      return false;
    }
    if (other is! BleCh) {
      return false;
    } else {
      return this.id == other.id;
    }
  }

  @override
  int get hashCode => this.id.hashCode;

  void notifyGetValue(arguments) {
    final service = findServiceById(arguments["serviceId"]);
    final Uint8List data = arguments["data"];
    final ch = BleCh.fromMap(arguments["ch"], service: service);
    _notifyDataCtl.add(BleNotifyData(ch, data));
  }

  @override
  void notifyListeners() {
    print("ble notify listeners");
    super.notifyListeners();
  }
}
