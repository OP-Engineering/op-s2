#include <jni.h>
#include "op-engineering-op-secure-storage.h"

extern "C"
JNIEXPORT jdouble JNICALL
Java_com_opengineering_opsecurestorage_OpSecureStorageModule_nativeMultiply(JNIEnv *env, jclass type, jdouble a, jdouble b) {
    return opengineering_opsecurestorage::multiply(a, b);
}
