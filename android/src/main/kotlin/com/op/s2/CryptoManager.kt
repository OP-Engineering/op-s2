package com.op.s2

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class CryptoManager(private val context: Context) {
    private val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(SHARED_PREFS_FILENAME, Context.MODE_PRIVATE)
    private val biometricPrefs: SharedPreferences =
        context.getSharedPreferences(BIOMETRICS_SHARED_PREFS_FILENAME, Context.MODE_PRIVATE)

    init {
        getOrCreateKey(MASTER_KEY_ALIAS, requireUserAuthentication = false)
        getOrCreateKey(BIOMETRIC_KEY_ALIAS, requireUserAuthentication = true)

        // The non-biometric legacy store needs no authentication to read, so it's
        // migrated eagerly here. The biometric one is migrated lazily, entry by
        // entry, from get()/set() below — decrypting it requires an authenticated
        // window, which we only have once a BiometricPrompt has already succeeded
        // (see OPS2Bridge.runBiometricPrompt).
        migrateLegacyStore(LEGACY_SHARED_PREFS_FILENAME, prefs, MASTER_KEY_ALIAS)
    }

    fun set(key: String, value: String, withBiometrics: Boolean = false) {
        if (withBiometrics) migrateLegacyEntry(key)
        val (target, alias) = target(withBiometrics)
        writeEntry(target, alias, key, value)
    }

    fun get(key: String, withBiometrics: Boolean = false): String? {
        if (withBiometrics) migrateLegacyEntry(key)
        val (target, alias) = target(withBiometrics)
        return readEntry(target, alias, key)
    }

    fun delete(key: String, withBiometrics: Boolean = false) {
        val (target, _) = target(withBiometrics)
        target.edit().remove(key).apply()
    }

    private fun target(withBiometrics: Boolean): Pair<SharedPreferences, String> =
        if (withBiometrics) biometricPrefs to BIOMETRIC_KEY_ALIAS else prefs to MASTER_KEY_ALIAS

    private fun writeEntry(target: SharedPreferences, alias: String, key: String, value: String) {
        val secretKey = keyStore.getKey(alias, null) as SecretKey
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val ciphertext = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val payload = cipher.iv + ciphertext
        target.edit().putString(key, Base64.encodeToString(payload, Base64.NO_WRAP)).apply()
    }

    private fun readEntry(target: SharedPreferences, alias: String, key: String): String? {
        val stored = target.getString(key, null) ?: return null
        val payload = Base64.decode(stored, Base64.NO_WRAP)
        val iv = payload.copyOfRange(0, IV_SIZE_BYTES)
        val ciphertext = payload.copyOfRange(IV_SIZE_BYTES, payload.size)
        val secretKey = keyStore.getKey(alias, null) as SecretKey
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(TAG_SIZE_BITS, iv))
        return String(cipher.doFinal(ciphertext), Charsets.UTF_8)
    }

    // By choosing AES/GCM/NoPadding directly against an AndroidKeyStore key, the
    // resulting KeyGenParameterSpec below is the same shape androidx.security.crypto's
    // MasterKey used internally (PURPOSE_ENCRYPT | PURPOSE_DECRYPT, BLOCK_MODE_GCM,
    // ENCRYPTION_PADDING_NONE, 256-bit key) — we're just talking to Keystore ourselves
    // instead of through the now-deprecated wrapper.
    private fun getOrCreateKey(alias: String, requireUserAuthentication: Boolean) {
        if (keyStore.containsAlias(alias)) return

        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(KEY_SIZE_BITS)

        if (requireUserAuthentication) {
            builder.setUserAuthenticationRequired(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(
                    AUTH_VALIDITY_SECONDS,
                    KeyProperties.AUTH_DEVICE_CREDENTIAL or KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            } else {
                @Suppress("DEPRECATION")
                builder.setUserAuthenticationValidityDurationSeconds(AUTH_VALIDITY_SECONDS)
            }
        }

        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        keyGenerator.init(builder.build())
        keyGenerator.generateKey()
    }

    // op-s2 <= 1.1.0 stored values via androidx.security.crypto's EncryptedSharedPreferences,
    // which Google has since deprecated in favor of talking to AndroidKeyStore directly (see
    // getOrCreateKey above). These helpers move any pre-existing data into the new format the
    // first time it's touched, then drop it from the legacy file — once old installs have aged
    // out, this migration path (and the security-crypto dependency it needs) can be removed.
    private fun migrateLegacyStore(legacyFilename: String, newTarget: SharedPreferences, alias: String) {
        val rawLegacyPrefs = context.getSharedPreferences(legacyFilename, Context.MODE_PRIVATE)
        if (rawLegacyPrefs.all.isEmpty()) return

        val legacyPrefs = openLegacyEncryptedPrefs(legacyFilename, requireUserAuthentication = false) ?: return
        for (key in legacyPrefs.all.keys) {
            val value = legacyPrefs.getString(key, null) ?: continue
            writeEntry(newTarget, alias, key, value)
        }
        rawLegacyPrefs.edit().clear().apply()
    }

    private fun migrateLegacyEntry(key: String) {
        if (biometricPrefs.contains(key)) return
        val rawLegacyPrefs = context.getSharedPreferences(LEGACY_BIOMETRICS_SHARED_PREFS_FILENAME, Context.MODE_PRIVATE)
        if (!rawLegacyPrefs.contains(key)) return

        val legacyPrefs = openLegacyEncryptedPrefs(
            LEGACY_BIOMETRICS_SHARED_PREFS_FILENAME,
            requireUserAuthentication = true
        ) ?: return
        val value = legacyPrefs.getString(key, null) ?: return
        writeEntry(biometricPrefs, BIOMETRIC_KEY_ALIAS, key, value)
        rawLegacyPrefs.edit().remove(key).apply()
    }

    private fun openLegacyEncryptedPrefs(filename: String, requireUserAuthentication: Boolean): SharedPreferences? {
        return try {
            val legacyMasterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .setUserAuthenticationRequired(requireUserAuthentication, AUTH_VALIDITY_SECONDS)
                .build()

            EncryptedSharedPreferences.create(
                context,
                filename,
                legacyMasterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            Log.w("OPS2", "Failed to open legacy encrypted store '$filename' for migration", e)
            null
        }
    }

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val KEY_SIZE_BITS = 256
        private const val IV_SIZE_BYTES = 12
        private const val TAG_SIZE_BITS = 128
        private const val AUTH_VALIDITY_SECONDS = 10

        private const val MASTER_KEY_ALIAS = "OPS2MasterKey"
        private const val BIOMETRIC_KEY_ALIAS = "OPS2BiometricMasterKey"

        private const val SHARED_PREFS_FILENAME = "OPS2SecurePrefs"
        private const val BIOMETRICS_SHARED_PREFS_FILENAME = "OPS2BiometricsSecurePrefs"

        // Filenames used by op-s2 <= 1.1.0 (androidx.security.crypto backed storage).
        private const val LEGACY_SHARED_PREFS_FILENAME = "OPS2EncryptedSharedPrefs"
        private const val LEGACY_BIOMETRICS_SHARED_PREFS_FILENAME = "OPS2BiometricsEncryptedSharedPrefs"
    }
}
