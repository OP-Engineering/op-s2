package com.op.s2

import androidx.appcompat.app.AppCompatActivity
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor
import java.util.concurrent.Semaphore
import android.util.Log

class OPS2Bridge(reactContext: ReactApplicationContext) {
  private val context = reactContext;
  private val cryptoManager = CryptoManager(reactContext)
  private external fun initialize(jsiPtr: Long)

  fun setItem(key: String, value: String, withBiometrics: Boolean) {
    if(withBiometrics) {
      val activity = this.context.currentActivity
      val executor: Executor = ContextCompat.getMainExecutor(this.context)
      val promptInfo = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Please authenticate")
        .setSubtitle("Biometric authentication is required to safely read/write data")
        .setNegativeButtonText("Cancel")
        .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        .build()

      var mutex = Semaphore(0)
      var authenticationCallback = TSSAuthenticationCallback(mutex)

      activity?.runOnUiThread {
        var biometricPrompt = BiometricPrompt(activity as AppCompatActivity, executor, authenticationCallback)
        biometricPrompt.authenticate(promptInfo)
      }

      try {
        mutex.acquire()
      } catch (e: Exception) {
        Log.e("BLAH", "Interrupted mutex exception");
      }

      if(authenticationCallback.isAuthenticated) {
        cryptoManager.set(key, value, true)
      } else {
        throw Exception(authenticationCallback.errorStr)
      }
    } else {
      cryptoManager.set(key, value)
    }
  }

  fun getItem(key: String, withBiometrics: Boolean): String? {

    if(withBiometrics) {
      val activity = this.context.currentActivity
      val executor: Executor = ContextCompat.getMainExecutor(this.context)
      val promptInfo = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Please authenticate")
        .setSubtitle("Biometric authentication is required to safely read/write data")
        .setNegativeButtonText("Cancel")
        .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        .build()

      var mutex = Semaphore(0)
      var authenticationCallback = TSSAuthenticationCallback(mutex)

      activity?.runOnUiThread {

        var biometricPrompt = BiometricPrompt(activity as AppCompatActivity, executor, authenticationCallback)
        biometricPrompt.authenticate(promptInfo)
      }

      try {
        mutex.acquire()
      } catch (e: Exception) {
      }

      if(authenticationCallback.isAuthenticated) {
        val value = cryptoManager.get(key, true)
        return value;
      } else {
        throw Exception(authenticationCallback.errorStr)
      }

    } else {
      return cryptoManager.get(key)
    }

    return null
  }

  fun deleteItem(key: String, withBiometrics: Boolean) {

    if(withBiometrics) {
      val activity = this.context.currentActivity
      val executor: Executor = ContextCompat.getMainExecutor(this.context)
      val promptInfo = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Please authenticate")
        .setSubtitle("Biometric authentication is required to safely read/write data")
        .setNegativeButtonText("Cancel")
        .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        .build()

      var mutex = Semaphore(0)
      var authenticationCallback = TSSAuthenticationCallback(mutex)

      activity?.runOnUiThread {
        var biometricPrompt = BiometricPrompt(activity as AppCompatActivity, executor, authenticationCallback)
        biometricPrompt.authenticate(promptInfo)
      }

      try {
        mutex.acquire()
      } catch (e: Exception) {

      }

      if(authenticationCallback.isAuthenticated) {
        cryptoManager.delete(key, true)
      } else {
        throw Exception(authenticationCallback.errorStr)
      }
    } else {
      cryptoManager.delete(key)
    }
  }

  fun install(context: ReactContext) {
      val jsContextPointer = context.javaScriptContextHolder.get()

      initialize(
          jsContextPointer,
      )
  }
}
