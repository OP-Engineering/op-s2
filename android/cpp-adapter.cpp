#include "bindings.h"
#include "logs.h"
#include <ReactCommon/CallInvokerHolder.h>
#include <fbjni/fbjni.h>
#include <iostream>
#include <jni.h>
#include <jsi/jsi.h>
#include <mutex>
#include <typeinfo>

namespace jni = facebook::jni;
namespace react = facebook::react;
namespace jsi = facebook::jsi;

JavaVM *java_vm;
jclass java_class;
jobject java_object;

/**
 * A simple callback function that allows us to detach current JNI Environment
 * when the thread
 * See https://stackoverflow.com/a/30026231 for detailed explanation
 */
void DeferThreadDetach(JNIEnv *env) {
  static pthread_key_t thread_key;
  static std::once_flag create_key_once;

  // Set up a Thread Specific Data key, and a callback that
  // will be executed when a thread is destroyed.
  // This is only done once, across all threads, and the value
  // associated with the key for any given thread will initially
  // be NULL.
  std::call_once(create_key_once, [] {
    const auto err = pthread_key_create(&thread_key, [](void *ts_env) {
      if (ts_env) {
        java_vm->DetachCurrentThread();
      }
    });
    if (err) {
      // Failed to create TSD key. Throw an exception if you want to.
    }
  });

  // For the callback to actually be executed when a thread exits
  // we need to associate a non-NULL value with the key on that thread.
  // We can use the JNIEnv* as that value.
  const auto ts_env = pthread_getspecific(thread_key);
  if (!ts_env) {
    if (pthread_setspecific(thread_key, env)) {
      // Failed to set thread-specific value for key. Throw an exception if you
      // want to.
    }
  }
}

/**
 * Get a JNIEnv* valid for this thread, regardless of whether
 * we're on a native thread or a Java thread.
 * If the calling thread is not currently attached to the JVM
 * it will be attached, and then automatically detached when the
 * thread is destroyed.
 *
 * See https://stackoverflow.com/a/30026231 for detailed explanation
 */
JNIEnv *GetJniEnv() {
  JNIEnv *env = nullptr;
  // We still call GetEnv first to detect if the thread already
  // is attached. This is done to avoid setting up a DetachCurrentThread
  // call on a Java thread.

  // g_vm is a global.
  auto get_env_result = java_vm->GetEnv((void **)&env, JNI_VERSION_1_6);
  if (get_env_result == JNI_EDETACHED) {
    if (java_vm->AttachCurrentThread(&env, NULL) == JNI_OK) {
      DeferThreadDetach(env);
    } else {
      // Failed to attach thread. Throw an exception if you want to.
    }
  } else if (get_env_result == JNI_EVERSION) {
    // Unsupported JNI version. Throw an exception if you want to.
  }
  return env;
}

jstring string2jstring(JNIEnv *env, const char *str) {
  if (str == nullptr) {
    return env->NewStringUTF("");
  }
  return (*env).NewStringUTF(str);
}

jobject
buildBiometricPromptOptions(JNIEnv *env,
                            const ops2::BiometricPromptOptions &options) {
  jclass optsClass = env->FindClass("com/op/s2/BiometricPromptOptions");
  if (optsClass == nullptr) {
    env->ExceptionClear();
    return nullptr;
  }

  jmethodID optsCtor = env->GetMethodID(
      optsClass, "<init>",
      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ZZ)V");
  if (optsCtor == nullptr) {
    env->ExceptionClear();
    return nullptr;
  }

  jstring jTitle = string2jstring(env, options.title.c_str());
  jstring jSubtitle = string2jstring(env, options.subtitle.c_str());
  jstring jNegative = string2jstring(env, options.negativeButtonText.c_str());

  return env->NewObject(optsClass, optsCtor, jTitle, jSubtitle, jNegative,
                        (jboolean)options.allowDeviceCredential,
                        (jboolean)options.allowBiometricWeak);
}

void set(const char *key, const char *value, bool withBiometrics,
         ops2::BiometricPromptOptions options) {
  JNIEnv *jniEnv = GetJniEnv();
  java_class = jniEnv->GetObjectClass(java_object);
  jmethodID mid =
      jniEnv->GetMethodID(java_class, "setItem",
                          "(Ljava/lang/String;Ljava/lang/String;ZLcom/op/s2/"
                          "BiometricPromptOptions;)V");
  jstring jKey = string2jstring(jniEnv, key);
  jstring jVal = string2jstring(jniEnv, value);
  jobject jOpts = buildBiometricPromptOptions(jniEnv, options);

  jniEnv->CallVoidMethod(java_object, mid, jKey, jVal, withBiometrics, jOpts);

  jthrowable exObj = jniEnv->ExceptionOccurred();
  if (exObj) {
    jniEnv->ExceptionClear();

    jclass clazz = jniEnv->GetObjectClass(exObj);
    jmethodID getMessage =
        jniEnv->GetMethodID(clazz, "toString", "()Ljava/lang/String;");
    jstring message = (jstring)jniEnv->CallObjectMethod(exObj, getMessage);
    const char *mstr = jniEnv->GetStringUTFChars(message, NULL);
    throw std::runtime_error(std::string(mstr));
  }
}

std::string get(const char *key, bool withBiometrics,
                ops2::BiometricPromptOptions options) {
  JNIEnv *jniEnv = GetJniEnv();
  java_class = jniEnv->GetObjectClass(java_object);
  jmethodID mid =
      jniEnv->GetMethodID(java_class, "getItem",
                          "(Ljava/lang/String;ZLcom/op/s2/"
                          "BiometricPromptOptions;)Ljava/lang/String;");
  jstring jKey = string2jstring(jniEnv, key);
  jobject jOpts = buildBiometricPromptOptions(jniEnv, options);

  jstring result = (jstring)jniEnv->CallObjectMethod(java_object, mid, jKey,
                                                     withBiometrics, jOpts);

  jthrowable exObj = jniEnv->ExceptionOccurred();
  if (exObj) {
    jniEnv->ExceptionClear();

    jclass clazz = jniEnv->GetObjectClass(exObj);
    jmethodID getMessage =
        jniEnv->GetMethodID(clazz, "toString", "()Ljava/lang/String;");
    jstring message = (jstring)jniEnv->CallObjectMethod(exObj, getMessage);
    const char *mstr = jniEnv->GetStringUTFChars(message, NULL);
    throw std::runtime_error(std::string(mstr));
  }

  if (result == NULL) {
    // TODO revisit this
    return "";
  }

  std::string str = jniEnv->GetStringUTFChars(result, NULL);
  return str;
}

void del(const char *key, bool withBiometrics,
         ops2::BiometricPromptOptions options) {
  JNIEnv *jniEnv = GetJniEnv();
  java_class = jniEnv->GetObjectClass(java_object);
  jmethodID mid = jniEnv->GetMethodID(
      java_class, "deleteItem",
      "(Ljava/lang/String;ZLcom/op/s2/BiometricPromptOptions;)V");
  jstring jKey = string2jstring(jniEnv, key);
  jobject jOpts = buildBiometricPromptOptions(jniEnv, options);

  jniEnv->CallVoidMethod(java_object, mid, jKey, withBiometrics, jOpts);
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved) {
  java_vm = jvm;
  return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT void JNICALL
Java_com_op_s2_OPS2Bridge_initialize(JNIEnv *env, jobject thiz, jlong jsi_ptr) {
  auto rt = reinterpret_cast<jsi::Runtime *>(jsi_ptr);
  java_object = env->NewGlobalRef(thiz);

  ops2::install(*rt, &set, &get, &del);
}
