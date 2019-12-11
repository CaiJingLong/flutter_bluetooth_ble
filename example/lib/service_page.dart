import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_ble/bluetooth_ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

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

  List<String> receiveData = [];

  @override
  void initState() {
    super.initState();
    sub = device.notifyDataStream.listen((data) {
      print("接收到的消息: ${data.data.toList()}");
      receiveData.add(utf8.decode(data.data.toList()));
      if (mounted) {
        setState(() {});
      }
    });
    device.addListener(_onChange);
  }

  @override
  void dispose() {
    device.removeListener(_onChange);
    sub?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (mounted && !device.isConnect) {
      showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text("连接中断, 是否退出此页面"),
              actions: <Widget>[
                FlatButton(
                  child: Text("不"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text("退"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
    }
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
                Text("service: ${ch.service.id}"),
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
              Container(
                height: 10,
              ),
              RaisedButton(
                child: Text("显示接收消息日志"),
                onPressed: () {
                  final style = Theme.of(context).textTheme.body2;
                  showDialog(
                    context: context,
                    builder: (_) => Center(
                      child: Container(
                        color: Colors.white,
                        child: ListView.builder(
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              height: 30,
                              alignment: Alignment.center,
                              child: Text(
                                receiveData[index],
                                style: style,
                              ),
                            );
                          },
                          itemCount: receiveData.length,
                          shrinkWrap: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
              RaisedButton(
                child: Text("复制信息"),
                onPressed: () {
                  final serviceUUID = ch.service.id;
                  final characteristicsUUID = ch.id;
                  final text =
                      "service: $serviceUUID\ncharacteristics: $characteristicsUUID";
                  Clipboard.setData(ClipboardData(text: text));
                  showToast("信息已经被复制到剪切板:\n $text");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void writeData(BleCh ch) {
    // String data = "abc\n";
    // String data = "12345678901234567890qwertyuiopasdfghjklzxcvbnm" * 20;

    // data = "$data\n";

    // String data = "abc234567890-34567890-4567890567890\n";
    // final list = utf8.encode(data);

    final data = <int>[0x1D, 0x67, 0x68];

    device.writeData(ch: ch, data: Uint8List.fromList(data));
  }
}
