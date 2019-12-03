class BleCh {
  String service;
  String id;
  bool write;
  bool writeNoResponse;
  bool read;
  bool notifying;

  static BleCh fromMap(Map map, {String service}) {
    return BleCh()
      ..id = map["uuid"]
      ..service = service
      ..write = map["write"]
      ..writeNoResponse = map["writeableWithoutResponse"]
      ..read = map["readable"]
      ..notifying = map["notifying"];
  }
}
