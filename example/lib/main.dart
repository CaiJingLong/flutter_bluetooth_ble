import 'dart:io';

import 'package:bluetooth_ble/bluetooth_ble.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import 'device_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        home: new HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ble = BluetoothBle();

  List<BleDevice> get devices => ble.devices;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: StreamBuilder<BleDevice>(
          stream: ble.deviceStream,
          builder: (context, _) {
            return ListView(
              children: <Widget>[
                RaisedButton(
                  onPressed: _scan,
                  child: Text("扫描设备"),
                ),
                RaisedButton(
                  onPressed: () => _scanWithService(macServiceId),
                  child: Text("扫描1811设备"),
                ),
                RaisedButton(
                  onPressed: () => _scanWithService(uuid("18F0")),
                  child: Text("扫描18F0设备"),
                ),
                RaisedButton(
                  onPressed: () => _scanWithService(uuid("FFF0")),
                  child: Text("扫描FFF0设备"),
                ),
                for (final device in devices) _buildItem(device)
              ],
            );
          }),
    );
  }

  void _scan() async {
    try {
      await ble.scan();
    } catch (e) {
      print(e.message);
    }
  }

  void _scanWithService(String uuid) async {
    try {
      await ble.scan(
        services: [uuid],
      );
    } on Exception catch (e) {
      print(e);
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return Center(
          child: Container(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  String get macServiceId {
    if (Platform.isIOS) {
      return "1811";
    }
    return "00001811-0000-1000-8000-00805f9b34fb";
  }

  String get serviceUUID {
    if (Platform.isIOS) {
      return "18f0";
    } else {
      return "000018f0-0000-1000-8000-00805f9b34fb";
    }
  }

  String uuid(String simpleUUID) {
    if (simpleUUID.length == 4) {
      if (Platform.isIOS) {
        return simpleUUID;
      }
      return "0000$simpleUUID-0000-1000-8000-00805f9b34fb";
    }
    return simpleUUID;
  }

  Widget _buildItem(BleDevice device) {
    return ListTile(
      title: Text(device.name),
      subtitle: Text(device.id),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DevicePage(
            device: device,
          ),
        ),
      ),
    );
  }
}
