package top.kikt.bt.ble.bluetooth_ble.core

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.os.Handler
import android.os.ParcelUuid

/// create 2019-12-03 by cai

class BleHelper {
  
  private val adapter = BluetoothAdapter.getDefaultAdapter()
  
  private val manager
    get() = adapter.bluetoothLeScanner
  
  val devices = ArrayList<BluetoothDevice>()
  
  inner class ScannerCallback : ScanCallback() {
    override fun onScanFailed(errorCode: Int) {
      super.onScanFailed(errorCode)
    }
    
    override fun onScanResult(callbackType: Int, result: ScanResult?) {
      super.onScanResult(callbackType, result)
      devices.contains(result?.device)
    }
    
    override fun onBatchScanResults(results: MutableList<ScanResult>?) {
      super.onBatchScanResults(results)
      
    }
  }
  
  private val callback = ScannerCallback()

//  val callback = object ScannerCallback()
  
  fun scanDevice(handler: ReplyHandler) {
    if (adapter.isEnabled) {
      return
    }
    
    val services: List<String>? = handler["services"]
    
    if (services != null) {
      
      val filters = arrayListOf<ScanFilter>()
      
      val settings = ScanSettings.Builder().apply {
      }.build()
      
      for (item in services) {
        val filter = ScanFilter.Builder().apply {
          setServiceUuid(ParcelUuid.fromString(item))
        }.build()
        filters.add(filter)
      }
      manager.startScan(filters, settings, callback)
    } else {
      manager.startScan(callback)
    }
    
    // 停止
    val seconds: Int = handler["time"]
    Handler().postDelayed({
      manager.stopScan(callback)
    }, (seconds * 1000).toLong())
  }
  
}
