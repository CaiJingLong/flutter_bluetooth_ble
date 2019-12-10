package top.kikt.bt.ble.bluetooth_ble.core

/// create 2019-12-10 by cai
object ConnectedBleManager {
  
  private var devicesMap: MutableMap<String, BleDevice> = HashMap()
  
  fun addDevice(device: BleDevice) {
    devicesMap[device.id] = device
  }
  
  fun removeDevice(device: BleDevice) {
    devicesMap.remove(device.id)
  }
  
  fun findDevice(id: String): BleDevice? {
    return devicesMap[id]
  }
  
  fun getConnectedDevices():List<BleDevice> {
    return devicesMap.values.toList()
  }
  
}