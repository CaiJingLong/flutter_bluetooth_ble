package top.kikt.bt.ble.bluetooth_ble

import android.util.Log

/// create 2019-11-27 by cai

class Logger(any: Any) {
  
  companion object {
    var level = LoggerLevel.Debug
  }
  
  private val tag = any.javaClass.simpleName
  
  fun verbose(any: Any?) {
    checkLevel(LoggerLevel.Verbose) {
      Log.v(tag, any.toString())
    }
  }
  
  fun debug(any: Any?) {
    checkLevel(LoggerLevel.Debug) {
      Log.d(tag, any.toString())
    }
  }
  
  fun info(any: Any?) {
    checkLevel(LoggerLevel.Info) {
      Log.i(tag, any.toString())
    }
  }
  
  fun warning(any: Any?) {
    checkLevel(LoggerLevel.Warning) {
      Log.w(tag, any.toString())
    }
  }
  
  fun error(any: Any?) {
    checkLevel(LoggerLevel.Error) {
      Log.e(tag, any.toString())
    }
  }
  
  private inline fun checkLevel(target: LoggerLevel, runnable: () -> Unit) {
    if (level <= target) {
      runnable()
    }
  }
}

val Any.logger: Logger
  get() = Logger(this)

enum class LoggerLevel {
  Verbose, Debug, Info, Warning, Error,
}