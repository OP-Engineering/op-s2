package com.op.s2

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext

class OPS2Bridge(reactContext: ReactApplicationContext) {
  private val cryptoManager = CryptoManager(reactContext)
  private external fun initialize(jsiPtr: Long)

  fun setItem(key: String, value: String, withBiometrics: Boolean) {
    try {
      if(withBiometrics) {
//        val activity = this.currentActivity
//        val executor: Executor = ContextCompat.getMainExecutor(this.reactApplicationContext)
//        val promptInfo = BiometricPrompt.PromptInfo.Builder()
//          .setTitle("Please authenticate")
//          .setSubtitle("Biometric authentication is required to safely read/write data")
//          .setNegativeButtonText("Cancel")
//          .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
//          .build()
//
//        var mutex = Semaphore(0)
//        var authenticationCallback = TSSAuthenticationCallback(mutex)
//
//        activity?.runOnUiThread {
//          var biometricPrompt = BiometricPrompt(activity as AppCompatActivity, executor, authenticationCallback)
//          Log.w(Constants.TAG, "User should be prompted")
//          biometricPrompt.authenticate(promptInfo)
//          Log.w(Constants.TAG, "After prompt")
//        }
//
//        try {
//          mutex.acquire()
//        } catch (e: Exception) {
//          Log.e("BLAH", "Interrupted mutex exception");
//        }
//
//        if(authenticationCallback.isAuthenticated) {
//          cryptoManager.set(key, value, true)
//        }
      } else {
        cryptoManager.set(key, value)
      }
    } catch (e: Exception) {
//      Log.w("setItem", e.localizedMessage)
//      obj.putString("error", "Could not save value")
    }
    return
  }

  fun getItem(key: String, withBiometrics: Boolean): String? {
    try {
      if(withBiometrics) {
//        val activity = this.currentActivity
//        val executor: Executor = ContextCompat.getMainExecutor(this.reactApplicationContext)
//        val promptInfo = BiometricPrompt.PromptInfo.Builder()
//          .setTitle("Please authenticate")
//          .setSubtitle("Biometric authentication is required to safely read/write data")
//          .setNegativeButtonText("Cancel")
//          .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
//          .build()
//
//        var mutex = Semaphore(0)
//        var authenticationCallback = TSSAuthenticationCallback(mutex)
//
//        activity?.runOnUiThread {
//
//          var biometricPrompt = BiometricPrompt(activity as AppCompatActivity, executor, authenticationCallback)
//          Log.w(Constants.TAG, "User should be prompted")
//          biometricPrompt.authenticate(promptInfo)
//          Log.w(Constants.TAG, "After prompt")
//        }
//
//        try {
//          mutex.acquire()
//        } catch (e: Exception) {
//          Log.e("BLAH", "Interrupted mutex exception");
//        }
//
//        if(authenticationCallback.isAuthenticated) {
//          val value = cryptoManager.get(key, true)
//          obj.putString("value", value)
//        }
      }

      val value = cryptoManager.get(key)
      return value

    } catch(e: Exception) {
//      obj.putString("error", "Could not get value")
    }
    return null
  }

  fun deleteItem(key: String, withBiometrics: Boolean) {
    try {
      if(withBiometrics) {
//        val activity = this.currentActivity
//        val executor: Executor = ContextCompat.getMainExecutor(this.reactApplicationContext)
//        val promptInfo = BiometricPrompt.PromptInfo.Builder()
//          .setTitle("Please authenticate")
//          .setSubtitle("Biometric authentication is required to safely read/write data")
//          .setNegativeButtonText("Cancel")
//          .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
//          .build()
//
//        var mutex = Semaphore(0)
//        var authenticationCallback = TSSAuthenticationCallback(mutex)
//
//        activity?.runOnUiThread {
//
//          var biometricPrompt = BiometricPrompt(activity as AppCompatActivity, executor, authenticationCallback)
//          Log.w(Constants.TAG, "User should be prompted")
//          biometricPrompt.authenticate(promptInfo)
//          Log.w(Constants.TAG, "After prompt")
//        }
//
//        try {
//          mutex.acquire()
//        } catch (e: Exception) {
//          Log.e("BLAH", "Interrupted mutex exception");
//        }
//
//        if(authenticationCallback.isAuthenticated) {
//          cryptoManager.delete(key, true)
//        }
      } else {

        cryptoManager.delete(key)
      }
    } catch(e: Exception) {
//      obj.putString("error", "Could not get value")
    }
  }

  fun install(context: ReactContext) {
      val jsContextPointer = context.javaScriptContextHolder.get()

      initialize(
          jsContextPointer,
      )
  }
}
