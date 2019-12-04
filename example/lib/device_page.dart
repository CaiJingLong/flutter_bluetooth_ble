import 'package:flutter/material.dart';
import 'package:bluetooth_ble/bluetooth_ble.dart';
import 'package:oktoast/oktoast.dart';

import 'service_page.dart';

class DevicePage extends StatefulWidget {
  final BleDevice device;

  const DevicePage({
    Key key,
    @required this.device,
  }) : super(key: key);

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  BleDevice get device => widget.device;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: device,
        builder: (context, _) {
          return buildScaffold();
        });
  }

  Scaffold buildScaffold() {
    final isConnect = device.isConnect;
    final services = device.service;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: ListView(
        children: <Widget>[
          RaisedButton(
            child: Text(isConnect ? "断开" : "连接"),
            onPressed: () {
              if (!isConnect) {
                widget.device.connect();
              } else {
                widget.device.disconnect();
              }
            },
          ),
          RaisedButton(
            child: Text("扫描服务"),
            onPressed: () {
              if (!device.isConnect) {
                showToast("请先连接");
                return;
              }
              device.discoverServices();
            },
          ),
          for (final service in services) _buildService(service)
        ],
      ),
    );
  }

  Widget _buildService(BleService service) {
    return ListTile(
      title: Text(service.id),
      onTap: () async {
        await device.discoverCharacteristics(service);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServicePage(
              device: device,
              service: service,
            ),
          ),
        );
      },
    );
  }
}
