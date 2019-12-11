package top.kikt.bt.ble.bluetooth_ble

import android.Manifest
import android.annotation.SuppressLint
import androidx.fragment.app.FragmentActivity
import com.tbruyelle.rxpermissions2.RxPermissions
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import top.kikt.bt.ble.bluetooth_ble.core.BleHelper
import top.kikt.bt.ble.bluetooth_ble.core.ReplyHandler

class BluetoothBlePlugin(registrar: Registrar) : MethodCallHandler {
  
  private val manager = BleHelper(registrar)
  
  private val rxPermission: RxPermissions = RxPermissions(registrar.activity() as FragmentActivity)
  
  companion object {
    
    private lateinit var channel: MethodChannel
    
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      channel = MethodChannel(registrar.messenger(), "bluetooth_ble")
      channel.setMethodCallHandler(BluetoothBlePlugin(registrar))
    }
    
    fun invokeMethod(method: String, args: Any?) {
      channel.invokeMethod(method, args)
    }
  }
  
  @SuppressLint("CheckResult")
  override fun onMethodCall(call: MethodCall, result: Result) {
    val handler = ReplyHandler(call, result)
    rxPermission.request(
      Manifest.permission.BLUETOOTH_ADMIN,
      Manifest.permission.BLUETOOTH,
      Manifest.permission.ACCESS_COARSE_LOCATION,
      Manifest.permission.ACCESS_FINE_LOCATION
    ).subscribe { permissionResult ->
      if (permissionResult) {
        when (call.method) {
          "scan" -> {
            manager.scanDevice(handler)
          }
          "isEnabled" -> {
            handler.success(manager.isEnabled())
          }
        }
      } else {
        handler.error("403", "无蓝牙权限")
      }
    }
  }
  
}
