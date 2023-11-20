#include <jni.h>
#include "logs.h"
#include <ReactCommon/CallInvokerHolder.h>
#include <fbjni/fbjni.h>
#include <jni.h>
#include <jsi/jsi.h>
#include <typeinfo>

namespace jni = facebook::jni;
namespace react = facebook::react;
namespace jsi = facebook::jsi;

struct OPS2Bridge : jni::JavaClass<OPS2Bridge> {
    static constexpr auto kJavaDescriptor =
            "Lcom/op/s2/OPS2Bridge;";

    static void registerNatives() {
        javaClassStatic()->registerNatives(
                {
                        makeNativeMethod("installNativeJsi",
                                         OPS2Bridge::installNativeJsi),
                });
    }
private:
    static void installNativeJsi(
            jni::alias_ref<jni::JObject> thiz, jlong jsiRuntimePtr,
            jni::alias_ref<react::CallInvokerHolder::javaobject> jsCallInvokerHolder) {
        auto jsiRuntime = reinterpret_cast<jsi::Runtime *>(jsiRuntimePtr);
        auto jsCallInvoker = jsCallInvokerHolder->cthis()->getCallInvoker();

//        op::install(*jsiRuntime, jsCallInvoker, docPathString.c_str());
    }
};

JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *) {
    return jni::initialize(vm, [] { OPS2Bridge::registerNatives(); });
}
