package top.kikt.bt.ble.bluetooth_ble

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import top.kikt.bt.ble.bluetooth_ble.core.BleHelper
import top.kikt.bt.ble.bluetooth_ble.core.ReplyHandler

class BluetoothBlePlugin : MethodCallHandler {
  
  val manager = BleHelper()
  
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "bluetooth_ble")
      channel.setMethodCallHandler(BluetoothBlePlugin())
    }
  }
  
  override fun onMethodCall(call: MethodCall, result: Result) {
    val handler = ReplyHandler(call, result)
    when (call.method) {
      "scan" -> {
        manager.scanDevice(handler)
      }
    }
  }
}
