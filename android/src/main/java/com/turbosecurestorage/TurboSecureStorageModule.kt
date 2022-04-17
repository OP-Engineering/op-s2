package com.turbosecurestorage
import com.facebook.react.bridge.*
import android.util.Log
import java.util.ArrayList

class TurboSecureStorageModule(reactContext: ReactApplicationContext?) :
  NativeTurboSecureStorageSpec(reactContext) {

  private val keystore = TurboKeyStore()

//  public static boolean isRTL(Locale locale) {
//
//    final int directionality = Character.getDirectionality(locale.getDisplayName().charAt(0));
//    return directionality == Character.DIRECTIONALITY_RIGHT_TO_LEFT ||
//            directionality == Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC;
//  }

  override fun setItem(key: String, value: String): WritableMap {
//     Locale initialLocale = Locale.getDefault();
//      if (isRTL(initialLocale)) {
//          Locale.setDefault(Locale.ENGLISH);
//          rnKeyStore.setCipherText(getReactApplicationContext(), key, value);
//          Locale.setDefault(initialLocale);
//          promise.resolve("RNSecureStorage: Key stored/updated successfully");
//      } else {
    Log.i("TURBO_SECURE_STORAGE", "Storing: $key and $value")
          keystore.setCipherText(reactApplicationContext, key, value);
//          promise.resolve("RNSecureStorage: Key stored/updated successfully");
//      }
      
    val obj = WritableNativeMap()
    return obj
  }

  override fun getItem(key: String): WritableMap {

    val obj = WritableNativeMap()
    try {
      val data = keystore.getPlainText(reactApplicationContext, key)
      obj.putString("value", data)
    } catch (e: Exception) {
      obj.putString("error", "Could not read value")
    }
    return obj
  }

  override fun deleteItem(key: String): WritableMap {
    val fileDeleted = ArrayList<Boolean>()

    for (filename in arrayOf(
      Constants.SKS_DATA_FILENAME + key,
      Constants.SKS_KEY_FILENAME + key
    )) {
      fileDeleted.add(reactApplicationContext.deleteFile(filename))
    }
    if (!fileDeleted.get(0) || !fileDeleted.get(1)) {
//      promise.reject("404", "RNSecureStorage: Could not find the key to delete.")
    } else {
//      promise.resolve("RNSecureStorage: Key removed successfully")
    }
    val obj = WritableNativeMap()
    return obj
  }

  override fun getName(): String {
    return NAME
  }
  
  companion object {
    const val NAME = "TurboSecureStorage"
  }
}
