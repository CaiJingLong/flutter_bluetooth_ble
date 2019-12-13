package top.kikt.bt.ble.bluetooth_ble.core

import android.bluetooth.BluetoothDevice
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/// create 2019-12-04 by cai


abstract class IBleDevice(protected val registrar: PluginRegistry.Registrar, protected val device: BluetoothDevice, private val rssi: Int) : MethodChannel.MethodCallHandler {
  
  val id: String = device.address
  
  val notifyingMap = HashMap<String, Boolean>()
  
  private val channel = MethodChannel(registrar.messenger(), "top.kikt/ble/$id")
  
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
  
  companion object {
    private val mainHandler = Handler(Looper.getMainLooper())
  }
  
  fun invokeMethod(method: String, any: Any? = null) {
    mainHandler.post {
      channel.invokeMethod(method, any)
    }
  }
}
