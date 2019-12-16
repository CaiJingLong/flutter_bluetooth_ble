package top.kikt.bt.ble.bluetooth_ble.core

import android.bluetooth.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.bt.ble.bluetooth_ble.ext.checkProperty
import top.kikt.bt.ble.bluetooth_ble.ext.toMap
import top.kikt.bt.ble.bluetooth_ble.logger
import java.util.*
import kotlin.collections.ArrayList

/// create 2019-12-13 by cai


class BleDevice(registrar: PluginRegistry.Registrar, device: BluetoothDevice, rssi: Int) : IBleDevice(registrar, device, rssi) {
  
  private var gatt: BluetoothGatt? = null
  
  private var services = ArrayList<BluetoothGattService>()
  
  inner class GattCallback : BluetoothGattCallback() {
    override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
      super.onConnectionStateChange(gatt, status, newState)
      logger.info("current connected status = $status, newState = $newState")
      when (newState) {
        BluetoothGatt.STATE_CONNECTED -> {
          notifyConnectState(gatt, true)
        }
        BluetoothGatt.STATE_CONNECTING -> {
        }
        BluetoothGatt.STATE_DISCONNECTED -> {
          notifyingMap.clear()
          notifyConnectState(gatt, false)
        }
        BluetoothGatt.STATE_DISCONNECTING -> {
        }
      }
    }
    
    private fun notifyConnectState(gatt: BluetoothGatt?, isConnect: Boolean) {
      if (isConnect) {
        ConnectedBleManager.addDevice(this@BleDevice)
        invokeMethod("onConnect")
      } else {
        ConnectedBleManager.removeDevice(this@BleDevice)
        invokeMethod("onDisconnect")
        gatt?.close()
      }
    }
    
    override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
      super.onServicesDiscovered(gatt, status)
      val services = gatt?.services
      if (services != null) {
        this@BleDevice.services.clear()
        this@BleDevice.services.addAll(services)
        val serviceResult = services.map { it.uuid.toString() }
        discoverServiceHandler?.success(serviceResult)
      } else {
        discoverServiceHandler?.success(arrayListOf<String>())
      }
      discoverServiceHandler = null
    }
    
    override fun onCharacteristicChanged(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?) {
      super.onCharacteristicChanged(gatt, characteristic)
      /// 接收消息
      if (characteristic == null) {
        return
      }
      invokeMethod("notifyValue", mapOf(
        "serviceId" to characteristic.service.uuid.toString(),
        "data" to characteristic.value,
        "ch" to characteristic.toMap(true)
      ))
    }
    
    override fun onCharacteristicWrite(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?, status: Int) {
      super.onCharacteristicWrite(gatt, characteristic, status)
      logger.debug("onCharacteristicWrite: status=$status, value = ${characteristic?.value}")
    }
    
    override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
      super.onMtuChanged(gatt, mtu, status)
      mtuHandler?.success(mtu)
      logger.info("mtu设置成功 , 当前mtu = $mtu, status = $status")
    }
  }
  
  private val callback = GattCallback()
  
  var discoverServiceHandler: ReplyHandler? = null
  
  var mtuHandler: ReplyHandler? = null
  
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val handler = ReplyHandler(call, result)
    when (call.method) {
      "connect" -> {
        val type = handler.param<Int>("type") ?: BluetoothDevice.TRANSPORT_LE
        this.gatt = device.connectGatt(registrar.activity(), false, callback, type)
      }
      "requestMtu" -> {
        mtuHandler = handler
        val mtu = handler.param<Int>("mtu") ?: 512
        gatt?.requestMtu(mtu)
      }
      "disconnect" -> {
        gatt?.disconnect()
      }
      "discoverServices" -> {
        discoverServiceHandler = handler
        gatt?.discoverServices()
      }
      "discoverCharacteristics" -> {
        val serviceId = call.argument<String>("service")!!
        val service = gatt?.getService(UUID.fromString(serviceId))
        val characteristicsList = service?.characteristics
        val resultArray = ArrayList<Map<String, Any>>()
        
        if (characteristicsList != null) {
          for (item in characteristicsList) {
            val notifying = notifyingMap[item.uuid.toString()] ?: false
            resultArray.add(item.toMap(notifying))
          }
        }
        
        handler.success(resultArray)
      }
      "changeNotify" -> {
        val chId = call.argument<String>("ch")!!
        val serviceId = call.argument<String>("service")!!
        val notify = call.argument<Boolean>("notify")!!
        
        val service = gatt?.getService(UUID.fromString(serviceId))
        val ch = service?.getCharacteristic(UUID.fromString(chId))
        
        if (ch != null) {
          val notifyResult = setNotify(ch, notify)
          if (notifyResult) {
            notifyingMap[chId] = notify
            invokeMethod("notifyState", mapOf(
              "serviceId" to serviceId,
              "ch" to ch.toMap(notify)
            ))
          }
        }
      }
      "writeData" -> {
        val chId = call.argument<String>("ch")!!
        val serviceId = call.argument<String>("service")!!
        val data = call.argument<ByteArray>("data")!!
        
        val service = gatt?.getService(UUID.fromString(serviceId)) ?: return
        val ch = service.getCharacteristic(UUID.fromString(chId)) ?: return
        
        ch.value = data
        gatt?.writeCharacteristic(ch)
        handler.success(1)
      }
      else -> {
      }
    }
  }
  
  // https://blog.csdn.net/ctlemon/article/details/82699144
  private fun setNotify(ch: BluetoothGattCharacteristic, notify: Boolean): Boolean {
    var result = gatt?.setCharacteristicNotification(ch, notify)
    
    if (result == true) {
      for (dp in ch.descriptors) {
        if (dp != null) {
          if (ch.checkProperty(BluetoothGattCharacteristic.PROPERTY_NOTIFY)) {
            if (notify) {
              dp.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            } else {
              dp.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            }
          } else if (ch.checkProperty(BluetoothGattCharacteristic.PROPERTY_INDICATE)) {
            if (notify) {
              dp.value = BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
            } else {
              dp.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            }
          }
          result = gatt?.writeDescriptor(dp)
        }
      }
    }
    return result ?: false
  }
}
