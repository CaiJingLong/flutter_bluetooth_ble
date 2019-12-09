import 'package:flutter/widgets.dart';

import 'ble_ch.dart';
import 'ble_device.dart';
import 'utils/string_utils.dart';

class BleService with ChangeNotifier {
  final String id;
  final BleDevice device;
  List<BleCh> chs = [];

  BleService(
    this.device,
    this.id,
  );

  void addChs(List<BleCh> chs) {
    this.chs.addAll(chs);
    notifyListeners();
  }

  BleCh findCh(String chId) {
    if (chs.isEmpty) {
      return null;
    }
    return chs.firstWhere(
      (test) => StringUtils.equalsIgnoreCase(test.id, chId),
      orElse: () => null,
    );
  }

  void updateCh(BleCh ch) {
    final index = chs.indexOf(ch);
    if (index != -1) {
      chs.replaceRange(index, index + 1, [ch]);
    }
    notifyListeners();
  }

  void resetCh(List<BleCh> result) {
    this.chs.clear();
    this.chs.addAll(result);
    notifyListeners();
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
}
