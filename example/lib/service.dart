import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_ble/bluetooth_ble.dart';
import 'package:flutter/material.dart';

class ServicePage extends StatefulWidget {
  final BleDevice device;
  final String service;
  final List<BleCh> chs;

  const ServicePage({
    Key key,
    this.device,
    this.service,
    this.chs,
  }) : super(key: key);

  @override
  _ServicePageState createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  BleDevice get device => widget.device;

  @override
  Widget build(BuildContext context) {
    final chs = widget.chs;
    return Scaffold(
      appBar: AppBar(
        title: Text("${device.id}"),
      ),
      body: ListView.separated(
        itemBuilder: (c, i) => _buildItem(chs[i]),
        itemCount: chs.length,
        separatorBuilder: (_, __) => Container(
          height: 1,
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildItem(BleCh ch) {
    return ListTile(
      title: Text(ch.id),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("service: ${ch.service}"),
          Text("read: ${ch.read}"),
          Text("write: ${ch.write}"),
          Text("writeNoResponse: ${ch.writeNoResponse}"),
          Text("notifying: ${ch.notifying}"),
        ],
      ),
      onTap: () {
        writeData(ch);
      },
    );
  }

  void writeData(BleCh ch) {
    String data = "abc\n";
    final list = utf8.encode(data);
    device.writeData(ch: ch, data: Uint8List.fromList(list));
  }
}
