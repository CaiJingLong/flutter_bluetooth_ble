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

  List<BleDevice> devices = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        children: <Widget>[
          RaisedButton(
            onPressed: _scan,
            child: Text("scan"),
          ),
          for (final device in devices) _buildItem(device)
        ],
      ),
    );
  }

  void _scan() async {
    final devices = await ble.scan();
    print(devices);

    this.devices = devices;
    setState(() {});
  }

  String get serviceUUID {
    if (Platform.isIOS) {
      return "18f0";
    } else {
      return "000018f0-0000-1000-8000-00805f9b34fb";
    }
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
