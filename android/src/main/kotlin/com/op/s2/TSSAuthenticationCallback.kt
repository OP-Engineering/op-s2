package com.op.s2

import android.util.Log
import androidx.biometric.BiometricPrompt
import java.util.concurrent.Semaphore;

class TSSAuthenticationCallback(val mutex: Semaphore): BiometricPrompt.AuthenticationCallback() {
    var isAuthenticated = false
    var errorStr: String = ""

    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
        Log.e("BLAH", "authentication error $errString")
        errorStr = errString.toString();
        super.onAuthenticationError(errorCode, errString)
        mutex.release()
    }

    override fun onAuthenticationFailed() {
//        Log.e(Constants.TAG, "authentication failed!")
        super.onAuthenticationFailed()
        mutex.release()
    }

    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
        super.onAuthenticationSucceeded(result)
        isAuthenticated = true;
        mutex.release()
    }
}
