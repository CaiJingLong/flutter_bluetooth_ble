package top.kikt.bt.ble.bluetooth_ble.core

import android.bluetooth.*
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.bt.ble.bluetooth_ble.ext.checkProperty
import top.kikt.bt.ble.bluetooth_ble.ext.toMap
import top.kikt.bt.ble.bluetooth_ble.logger
import java.util.*
import kotlin.collections.ArrayList
import kotlin.collections.HashMap

/// create 2019-12-04 by cai


abstract class IBleDevice(protected val registrar: PluginRegistry.Registrar, protected val device: BluetoothDevice, private val rssi: Int) : MethodChannel.MethodCallHandler, DelegateInvoke {
  
  val id: String = device.address
  
  val notifyingMap = HashMap<String, Boolean>()
  
  override val channel = MethodChannel(registrar.messenger(), "top.kikt/ble/$id")
  
  fun `init`() {
    channel.setMethodCallHandler(this)
  }
  
  override fun equals(other: Any?): Boolean {
    if (this === other) return true
    if (javaClass != other?.javaClass) return false
    
    other as IBleDevice
    
    if (id != other.id) return false
    
    return true
  }
  
  override fun hashCode(): Int {
    return id.hashCode()
  }
  
  
  fun toMap(): Map<String, Any> {
    return mapOf(
      "id" to id,
      "name" to (device.name ?: ""),
      "rssi" to rssi
    )
  }
  
}

class BleDevice(registrar: PluginRegistry.Registrar, device: BluetoothDevice, rssi: Int) : IBleDevice(registrar, device, rssi) {
  
  private var gatt: BluetoothGatt? = null
  
  private var services = ArrayList<BluetoothGattService>()
  
  inner class GattCallback : BluetoothGattCallback() {
    override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
      super.onConnectionStateChange(gatt, status, newState)
      logger.info("status = $status, newState = $newState")
      when (newState) {
        BluetoothGatt.STATE_CONNECTED -> {
          notifyConnectState(true)
        }
        BluetoothGatt.STATE_CONNECTING -> {
        }
        BluetoothGatt.STATE_DISCONNECTED -> {
          notifyingMap.clear()
          notifyConnectState(false)
        }
        BluetoothGatt.STATE_DISCONNECTING -> {
        }
      }
    }
    
    private fun notifyConnectState(isConnect: Boolean) {
      if (isConnect) {
        invokeMethod("onConnect")
      } else {
        invokeMethod("onDisconnect")
      }
    }
    
    override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
      super.onServicesDiscovered(gatt, status)
      val services = gatt?.services
      if (services != null) {
        this@BleDevice.services.clear()
        this@BleDevice.services.addAll(services)
        invokeMethod("onDiscoverServices", services.map { it.uuid.toString() })
      }
    }
    
    override fun onCharacteristicChanged(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?) {
      super.onCharacteristicChanged(gatt, characteristic)
      logger.info("onCharacteristicChanged : characteristic = $characteristic")
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
  }
  
  private val callback = GattCallback()
  
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val handler = ReplyHandler(call, result)
    when (call.method) {
      "connect" -> {
        this.gatt = device.connectGatt(registrar.activity(), false, callback, BluetoothDevice.TRANSPORT_LE)
      }
      "disconnect" -> {
        gatt?.disconnect()
      }
      "discoverServices" -> {
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

private interface DelegateInvoke {
  val channel: MethodChannel
  
  companion object {
    private val mainHandler = Handler(Looper.getMainLooper())
  }
  
  fun invokeMethod(method: String, any: Any? = null) {
    mainHandler.post {
      channel.invokeMethod(method, any)
    }
  }
}