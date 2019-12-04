package top.kikt.bt.ble.bluetooth_ble.ext

import android.bluetooth.BluetoothGattCharacteristic

/// create 2019-12-04 by cai

val BluetoothGattCharacteristic.id
  get() = this.uuid.toString()

val BluetoothGattCharacteristic.writeable
  get() = checkProperty(BluetoothGattCharacteristic.PROPERTY_WRITE)

val BluetoothGattCharacteristic.writeableWithoutResponse
  get() = checkProperty(BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE)

val BluetoothGattCharacteristic.readable
  get() = checkProperty(BluetoothGattCharacteristic.PROPERTY_READ)

val BluetoothGattCharacteristic.notifiable
  get() = checkProperty(BluetoothGattCharacteristic.PROPERTY_NOTIFY)

//val BluetoothGattCharacteristic.isNotifying


fun BluetoothGattCharacteristic.toMap(notifying: Boolean = false): Map<String, Any> = mapOf(
  "uuid" to this.uuid.toString(),
  "write" to writeable,
  "writeableWithoutResponse" to writeableWithoutResponse,
  "readable" to readable,
  "notifiable" to notifiable,
  "notifying" to notifying
)

fun BluetoothGattCharacteristic.checkProperty(value: Int): Boolean {
  return this.properties and value != 0
}