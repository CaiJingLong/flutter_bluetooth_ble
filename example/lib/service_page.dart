import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_ble/bluetooth_ble.dart';
import 'package:flutter/material.dart';

class ServicePage extends StatefulWidget {
  final BleDevice device;
  final BleService service;

  const ServicePage({
    Key key,
    this.device,
    this.service,
  }) : super(key: key);

  @override
  _ServicePageState createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  BleDevice get device => widget.device;

  StreamSubscription<BleNotifyData> sub;

  @override
  void initState() {
    super.initState();
    sub = device.notifyDataStream.listen((data) {
      print("接收到的消息: ${data.data.toList()}");
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: widget.service,
        builder: (_, __) {
          final chs = widget.service.chs;
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
        });
  }

  Widget _buildItem(BleCh ch) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ListTile(
            title: Text(ch.id),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("notifiable: ${ch.notifiable}"),
                Text("service: ${ch.service}"),
                Text("read: ${ch.read}"),
                Text("write: ${ch.write}"),
                Text("writeNoResponse: ${ch.writeNoResponse}"),
                Text("notifying: ${ch.notifying}"),
              ],
            ),
          ),
        ),
        Container(
          width: 100,
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text("写数据"),
                onPressed: () {
                  writeData(ch);
                },
              ),
              Container(
                height: 10,
              ),
              RaisedButton(
                child: Text("监听"),
                onPressed: () {
                  device.changeNotify(ch);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void writeData(BleCh ch) {
    String data = "abc\n";
    final list = utf8.encode(data);
    device.writeData(ch: ch, data: Uint8List.fromList(list));
  }
}
