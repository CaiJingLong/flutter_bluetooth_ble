import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ble_ch.dart';
import 'ble_notify_data.dart';
import 'ble_service.dart';
import 'utils/string_utils.dart';

class BleDevice with ChangeNotifier implements Comparable<BleDevice> {
  StreamController<BleNotifyData> _notifyDataCtl = StreamController.broadcast();

  Stream<BleNotifyData> get notifyDataStream => _notifyDataCtl.stream;

  StreamController<bool> _connectStateCtl = StreamController.broadcast();

  Stream<bool> get connectStateStream => _connectStateCtl.stream;

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

  static Map<String, BleDevice> _deviceMap = {};

  static BleDevice fromMap(Map map) {
    var device = _deviceMap[map["id"]];
    if (device == null) {
      device = BleDevice()
        ..id = map["id"]
        ..name = map["name"]
        ..rssi = map["rssi"]
        ..refreshChannel();

      _deviceMap[device.id] = device;
    }
    return device;
  }

  @override
  void dispose() {
    _connectStateCtl.close();
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
      case "notifyState":
        onNotifyStateChange(call.arguments);
        break;
      case "notifyValue":
        notifyGetValue(call.arguments);
        break;
    }
  }

  /// [type] 是连接模式(仅android有效, ios会忽略), 对于某些设备, 需要设置为 2 才可连接, 默认值是2
  void connect([int type = 2]) {
    _channel.invokeMethod("connect", {"type": type});
  }

  void disconnect() {
    _channel.invokeMethod("disconnect");
  }

  Future<void> requestMtu(int mtu) async {
    final result = await _channel.invokeMethod("requestMtu");
    print("new mtu = $result");
  }

  @override
  String toString() {
    return 'BleDevice: {"name": $name, "id": $id, "rssi":$rssi}';
  }

  void onConnect() {
    isConnect = true;
    _connectStateCtl.add(true);
    notifyListeners();
  }

  void onDisconnect() {
    this.service.clear();
    isConnect = false;
    _connectStateCtl.add(false);
    notifyListeners();
  }

  void connectFail() {
    isConnect = false;
    notifyListeners();
  }

  Future<List<BleService>> discoverServices() async {
    final result = await _channel.invokeMethod("discoverServices");
    final List args = result;
    args.sort();
    final services = args.map((v) => BleService(this, v)).toList();
    this.service.clear();
    this.service.addAll(services);
    notifyListeners();
    return services;
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
    return service.firstWhere(
      (v) => StringUtils.equalsIgnoreCase(v.id, id),
      orElse: () => null,
    );
  }

  Future<BleCh> findCh(String serviceId, String chId) async {
    BleService service = findServiceById(serviceId);
    if (service == null) {
      await discoverServices();
      service = findServiceById(serviceId);
    }

    if (service == null) {
      return null;
    }
    final ch = service.findCh(chId);

    if (ch == null) {
      await discoverCharacteristics(service);
    }
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
