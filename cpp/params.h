#ifndef params_h
#define params_h

#include <jsi/jsi.h>

namespace ops2 {
namespace jsi = facebook::jsi;

static bool isNullish(const jsi::Value &v) {
  return v.isNull() || v.isUndefined();
}

/**
 * Validates the params object passed to `set`, `get` or `del`, so the
 * bindings can read every property afterwards without type errors.
 *
 * @param requiresValue Whether `value` must be a string (`set` only)
 * @return The error message, or nullptr when the params are valid
 */
static const char *validateParams(jsi::Runtime &rt, const jsi::Value *args, size_t count, bool requiresValue) {
  if (count < 1) return "Params object is missing";
  if (!args[0].isObject()) return "Params is not an object";

  jsi::Object params = args[0].asObject(rt);
  auto isNotString = [&](const char *name) {
    jsi::Value v = params.getProperty(rt, name);
    return !isNullish(v) && !v.isString();
  };

  if (!params.hasProperty(rt, "key")) return "Key property is missing";
  if (!params.getProperty(rt, "key").isString()) return "Key property is not a string";
  if (requiresValue) {
    if (!params.hasProperty(rt, "value")) return "Value property is missing";
    if (!params.getProperty(rt, "value").isString()) return "Value property is not a string";
  }
  jsi::Value withBiometrics = params.getProperty(rt, "withBiometrics");
  if (!isNullish(withBiometrics) && !withBiometrics.isBool()) return "withBiometrics property is not a boolean";
  if (isNotString("service")) return "service property is not a string";
  if (isNotString("accessGroup")) return "accessGroup property is not a string";
  return nullptr;
}

static bool readWithBiometrics(jsi::Runtime &rt, const jsi::Object &params) {
  jsi::Value v = params.getProperty(rt, "withBiometrics");
  return v.isBool() && v.getBool();
}

} // namespace ops2

#endif /* params_h */
