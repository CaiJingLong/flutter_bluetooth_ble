import 'package:bluetooth_ble/bluetooth_ble.dart';
import 'package:flutter/material.dart';

class ServicePage extends StatefulWidget {
  final BleDevice device;

  const ServicePage({Key key, this.device}) : super(key: key);

  @override
  _ServicePageState createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  BleDevice get device => widget.device;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
