package com.turbosecurestorage
import com.facebook.react.bridge.*
import android.content.Context.BATTERY_SERVICE
import android.os.BatteryManager

class TurboSecureStorageModule(reactContext: ReactApplicationContext?) :
  NativeTurboSecureStorageSpec(reactContext) {

  val batteryManager = reactContext?.getSystemService(BATTERY_SERVICE) as BatteryManager

  override fun setItem(key: String, value: String): WritableMap {
    val obj = WritableNativeMap()
    return obj
  }

  override fun getItem(key: String): WritableMap {
    val obj = WritableNativeMap()
    return obj
  }

  override fun deleteItem(key: String): WritableMap {
    val obj = WritableNativeMap()
    return obj
  }

  override fun getName(): String {
    return NAME
  }
  
  companion object {
    const val NAME = "TurboSecureStorage"
//
//    init {
//      System.loadLibrary("reactnativeturbostarter-jni")
//    }
  }
}
