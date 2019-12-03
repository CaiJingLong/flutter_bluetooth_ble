import 'ble_service.dart';

class BleCh {
  BleService service;
  String id;
  bool write;
  bool writeNoResponse;
  bool read;
  bool notifying;
  bool notifiable;

  static BleCh fromMap(Map map, {BleService service}) {
    return BleCh()
      ..id = map["uuid"]
      ..service = service
      ..write = map["write"]
      ..writeNoResponse = map["writeableWithoutResponse"]
      ..read = map["readable"]
      ..notifiable = map["notifiable"]
      ..notifying = map["notifying"];
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
  int get hashCode {
    return id.hashCode;
  }
}
