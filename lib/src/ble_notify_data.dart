import 'dart:typed_data';

import 'ble_ch.dart';

class BleNotifyData {
  final BleCh ch;

  final Uint8List data;

  BleNotifyData(this.ch, this.data);
}
