package com.turbosecurestorage
import android.content.Context
import com.facebook.react.bridge.*
import android.util.Log

class TurboSecureStorageModule(reactContext: ReactApplicationContext?) :
  NativeTurboSecureStorageSpec(reactContext) {
  private val cryptographyManager = CryptographyManager()
  private val ciphertextWrapper
    get() = cryptographyManager.getCiphertextWrapperFromSharedPrefs(
      this.reactApplicationContext,
      SHARED_PREFS_FILENAME,
      Context.MODE_PRIVATE,
      CIPHERTEXT_WRAPPER
    )

//  private val keystore = TurboKeyStore()

//  public static boolean isRTL(Locale locale) {
//
//    final int directionality = Character.getDirectionality(locale.getDisplayName().charAt(0));
//    return directionality == Character.DIRECTIONALITY_RIGHT_TO_LEFT ||
//            directionality == Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC;
//  }

  override fun setItem(key: String, value: String, options: ReadableMap): WritableMap {
    try {
      Log.w("TurboSecureStorage", "marker0")
      val cipher = cryptographyManager.getInitializedCipherForEncryption(key)
      Log.w("TurboSecureStorage", "marker1")
      val encryptedServerTokenWrapper = cryptographyManager.encryptData(value, cipher)
      Log.w("TurboSecureStorage", "marker2")
      cryptographyManager.persistCiphertextWrapperToSharedPrefs(
        encryptedServerTokenWrapper,
        this.reactApplicationContext,
        SHARED_PREFS_FILENAME,
        Context.MODE_PRIVATE,
        CIPHERTEXT_WRAPPER
      )
      Log.w("TurboSecureStorage", "marker3")
    } catch (e: Exception) {
      Log.w("TurboSecureStorage", e.localizedMessage)
//      obj.putString("error", "Could not read value")
    }

//    cryptographyManager.encryptData()
//     Locale initialLocale = Locale.getDefault();
//      if (isRTL(initialLocale)) {
//          Locale.setDefault(Locale.ENGLISH);
//          rnKeyStore.setCipherText(getReactApplicationContext(), key, value);
//          Locale.setDefault(initialLocale);
//      } else {
    Log.i("TURBO_SECURE_STORAGE", "Storing: $key and $value")
//          keystore.setCipherText(reactApplicationContext, key, value);
//      }
      
    val obj = WritableNativeMap()
    return obj
  }

  override fun getItem(key: String): WritableMap {

    val obj = WritableNativeMap()
    try {
      ciphertextWrapper?.let { textWrapper ->
        val cipher = cryptographyManager.getInitializedCipherForDecryption(
          key, textWrapper.initializationVector
        )
        val plaintext = cryptographyManager.decryptData(textWrapper.ciphertext, cipher)
        obj.putString("value", plaintext)
      }
    } catch (e: Exception) {
      obj.putString("error", "Could not read value")
    }
    return obj
  }

  override fun deleteItem(key: String): WritableMap {
//    val fileDeleted = ArrayList<Boolean>()
//
//    for (filename in arrayOf(
//      Constants.SKS_DATA_FILENAME + key,
//      Constants.SKS_KEY_FILENAME + key
//    )) {
//      fileDeleted.add(reactApplicationContext.deleteFile(filename))
//    }
//    if (!fileDeleted.get(0) || !fileDeleted.get(1)) {
//    } else {
//    }
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
