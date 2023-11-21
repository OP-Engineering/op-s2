#include <jni.h>
#include "logs.h"
#include <ReactCommon/CallInvokerHolder.h>
#include <fbjni/fbjni.h>
#include <jni.h>
#include <jsi/jsi.h>
#include <typeinfo>
#include "bindings.h"

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

void DeferThreadDetach(JNIEnv *env)
{
    static pthread_key_t thread_key;

    // Set up a Thread Specific Data key, and a callback that
    // will be executed when a thread is destroyed.
    // This is only done once, across all threads, and the value
    // associated with the key for any given thread will initially
    // be NULL.
    static auto run_once = []
    {
        const auto err = pthread_key_create(&thread_key, [](void *ts_env)
        {
            if (ts_env) {
                java_vm->DetachCurrentThread();
            } });
        if (err)
        {
            // Failed to create TSD key. Throw an exception if you want to.
        }
        return 0;
    }();

    // For the callback to actually be executed when a thread exits
    // we need to associate a non-NULL value with the key on that thread.
    // We can use the JNIEnv* as that value.
    const auto ts_env = pthread_getspecific(thread_key);
    if (!ts_env)
    {
        if (pthread_setspecific(thread_key, env))
        {
            // Failed to set thread-specific value for key. Throw an exception if you want to.
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
JNIEnv *GetJniEnv()
{
    JNIEnv *env = nullptr;
    // We still call GetEnv first to detect if the thread already
    // is attached. This is done to avoid setting up a DetachCurrentThread
    // call on a Java thread.

    // g_vm is a global.
    auto get_env_result = java_vm->GetEnv((void **)&env, JNI_VERSION_1_6);
    if (get_env_result == JNI_EDETACHED)
    {
        if (java_vm->AttachCurrentThread(&env, NULL) == JNI_OK)
        {
            DeferThreadDetach(env);
        }
        else
        {
            // Failed to attach thread. Throw an exception if you want to.
        }
    }
    else if (get_env_result == JNI_EVERSION)
    {
        // Unsupported JNI version. Throw an exception if you want to.
    }
    return env;
}

jstring string2jstring(JNIEnv *env, const char *str)
{
    return (*env).NewStringUTF(str);
}

void set(const char* key, const char* value, bool withBiometrics)
{
    JNIEnv *jniEnv = GetJniEnv();
    java_class = jniEnv->GetObjectClass(java_object);
    jmethodID mid = jniEnv->GetMethodID(java_class, "setItem", "(Ljava/lang/String;Ljava/lang/String;Z)V");
    jstring jKey = string2jstring(jniEnv, key);
    jstring jVal = string2jstring(jniEnv, value);
    jvalue params[3];
    params[0].l = jKey;
    params[1].l = jVal;
    params[2].z = withBiometrics;

    jniEnv->CallVoidMethodA(java_object, mid, params);
}

std::string get(const char* key, bool withBiometrics)
{
    JNIEnv *jniEnv = GetJniEnv();
    java_class = jniEnv->GetObjectClass(java_object);
    jmethodID mid = jniEnv->GetMethodID(java_class, "getItem", "(Ljava/lang/String;Z)Ljava/lang/String;");
    jstring jKey = string2jstring(jniEnv, key);
    jvalue params[3];
    params[0].l = jKey;
    params[1].z = withBiometrics;


    jstring result = (jstring)jniEnv->CallObjectMethodA(java_object, mid, params);
    if (result == NULL)
    {
        // TODO revisit this
        return "";
    }

    std::string str = jniEnv->GetStringUTFChars(result, NULL);
    return str;
}

void del(const char* key, bool withBiometrics)
{
    JNIEnv *jniEnv = GetJniEnv();
    java_class = jniEnv->GetObjectClass(java_object);
    jmethodID mid = jniEnv->GetMethodID(java_class, "deleteItem", "(Ljava/lang/String;Z)V");
    jstring jKey = string2jstring(jniEnv, key);
    jvalue params[2];
    params[0].l = jKey;
    params[1].z = withBiometrics;

    jniEnv->CallVoidMethodA(java_object, mid, params);
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved)
{
    java_vm = jvm;
    return JNI_VERSION_1_6;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_op_s2_OPS2Bridge_initialize(JNIEnv *env, jobject thiz, jlong jsi_ptr) {
    auto rt = reinterpret_cast<jsi::Runtime *>(jsi_ptr);
    java_object = env->NewGlobalRef(thiz);

    ops2::install(*rt, &set, &get, &del);
}
