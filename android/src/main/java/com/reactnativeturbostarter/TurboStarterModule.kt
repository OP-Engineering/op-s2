package com.reactnativeturbostarter
import com.facebook.react.bridge.*
import android.content.Context.BATTERY_SERVICE
import android.os.BatteryManager

class TurboStarterModule(reactContext: ReactApplicationContext?) :
  NativeTurboStarterSpec(reactContext) {

  val batteryManager = reactContext?.getSystemService(BATTERY_SERVICE) as BatteryManager

  override fun getGreeting(name: String): String {
    return String.format("Hello, %s!", name)
  }

  override fun getTurboArray(values: ReadableArray): WritableArray {
    val array = values.toArrayList()
    array.reverse()
    val reversed = WritableNativeArray()

    for (item in array) {
      if (item !is String) {
        continue
      }

      reversed.pushString(item)
    }
    return reversed
  }

  override fun getTurboObject(options: ReadableMap): WritableMap {
    val obj = WritableNativeMap()
    obj.putString("helloString", "Hello, World!")
    obj.putInt("magicNumber", 42)
    obj.putString("response", "res")
    return obj
  }

  override fun getTurboObjectGeneric(options: ReadableMap): WritableMap {
    val obj = WritableNativeMap()
    val input = options.getInt("magicNumber")

    obj.putInt("magicNumber", input * 6)
    return obj
  }

  override fun getTurboPromise(magicNumber: Double, promise: Promise) {
    when (magicNumber) {
        42.0 -> {
          promise.resolve(true)
        }
        7.0 -> {
          promise.reject("1", "You stepped on a mine")
        }
        else -> {
          promise.resolve(false)
        }
    }
  }

  override fun getBatteryLevel(): Double {
    return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY).toDouble()
  }

  override fun turboMultiply(num1: Double, num2: Double): Double {
    return nativeMultiply(num1, num2)
  }

  override fun getName(): String {
    return NAME
  }

  private external fun nativeMultiply(num1: Double, num2: Double): Double

  companion object {
    const val NAME = "TurboStarter"

    init {
      System.loadLibrary("reactnativeturbostarter-jni")
    }
  }
}
