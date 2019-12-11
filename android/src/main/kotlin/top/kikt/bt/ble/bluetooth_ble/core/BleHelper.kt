package top.kikt.bt.ble.bluetooth_ble.core

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import io.flutter.plugin.common.PluginRegistry
import top.kikt.bt.ble.bluetooth_ble.BluetoothBlePlugin
import top.kikt.bt.ble.bluetooth_ble.logger

/// create 2019-12-03 by cai

class BleHelper(private val registrar: PluginRegistry.Registrar) {
  
  private val adapter = BluetoothAdapter.getDefaultAdapter()
  
  private val manager
    get() = adapter.bluetoothLeScanner
  
  private val devicesMap = HashMap<String, BleDevice>()
  
  class ScannerCallback(private val bleHelper: BleHelper) : ScanCallback() {
    override fun onScanFailed(errorCode: Int) {
      super.onScanFailed(errorCode)
      logger.info("onScanFailed: errorCode = $errorCode")
      bleHelper.onScanFailed(errorCode)
    }
    
    override fun onScanResult(callbackType: Int, result: ScanResult?) {
      super.onScanResult(callbackType, result)
      logger.info("onScanResult: ${result?.device?.name}")
      bleHelper.onScanResult(callbackType, result)
    }
    
    override fun onBatchScanResults(results: MutableList<ScanResult>?) {
      super.onBatchScanResults(results)
      logger.info("onBatchScanResults: ${results?.joinToString { it.device.name }}")
      bleHelper.onBatchScanResults(results)
    }
  }
  
  private fun onBatchScanResults(results: MutableList<ScanResult>?) {
  }
  
  private fun onScanFailed(errorCode: Int) {
  }
  
  private fun onScanResult(callbackType: Int, result: ScanResult?) {
    if (result == null) {
      return
    }
    val id = result.device.address
    var device = devicesMap[id]
    if (device == null) {
      device = BleDevice(registrar, result.device, result.rssi).apply {
        init()
      }
      onFoundDevice(id, device)
    }
  }
  
  private fun onFoundDevice(id: String, device: BleDevice) {
    devicesMap[id] = device
    BluetoothBlePlugin.invokeMethod("found_device", device.toMap())
  }
  
  fun scanDevice(handler: ReplyHandler) {
    if (!adapter.isEnabled) {
      handler.success(-2)
      return
    }
    
    devicesMap.clear()
    
    val connectedDevices = ConnectedBleManager.getConnectedDevices()
    
    for (device in connectedDevices) {
      onFoundDevice(device.id, device)
    }
    
    val callback = ScannerCallback(this)
    
    val services: List<*>? = handler.param("services")
    
    if (services != null) {
      
      val filters = arrayListOf<ScanFilter>()
      
      val settings = ScanSettings.Builder().apply {
      }.build()
      
      for (item in services) {
        val filter = ScanFilter.Builder().apply {
          setServiceUuid(ParcelUuid.fromString(item.toString()))
        }.build()
        filters.add(filter)
      }
      manager.startScan(filters, settings, callback)
    } else {
      manager.startScan(callback)
    }
    
    // 停止
    val seconds = handler.param<Int>("time")!!
    Handler(Looper.getMainLooper()).postDelayed({
      manager.stopScan(callback)
      replyDevice(handler)
    }, (seconds * 1000).toLong())
  }
  
  private fun replyDevice(handler: ReplyHandler) {
    val devices = ArrayList<Map<String, Any>>()
    
    for (bleDevice in devicesMap.values) {
      devices.add(bleDevice.toMap())
    }
    handler.success(
      mapOf(
        "devices" to devices
      )
    )
  }
  
  fun isEnabled(): Boolean {
    return adapter.isEnabled
  }
  
}
