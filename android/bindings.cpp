#include "bindings.h"
#include "macros.h"
#include "params.h"
#include <iostream>
#include <jni.h>

namespace ops2 {
namespace jsi = facebook::jsi;

std::function<void(const char *, const char *, bool, BiometricPromptOptions)> _set;
std::function<std::string(const char *, bool, BiometricPromptOptions)> _get;
std::function<void(const char *, bool, BiometricPromptOptions)> _del;

static BiometricPromptOptions extractBiometricPromptOptions(jsi::Runtime &rt, const jsi::Object &params) {
  BiometricPromptOptions options;
  options.title = "Please authenticate";
  options.subtitle = "";
  options.negativeButtonText = "Cancel";
  options.allowDeviceCredential = false;
  options.allowBiometricWeak = false;

  if (!params.hasProperty(rt, "biometricPrompt")) {
    return options;
  }

  jsi::Value prop = params.getProperty(rt, "biometricPrompt");
  if (prop.isNull() || prop.isUndefined() || !prop.isObject()) {
    return options;
  }

  jsi::Object prompt = prop.asObject(rt);

  auto getString = [&](const char *name, const std::string &fallback) -> std::string {
    if (!prompt.hasProperty(rt, name)) return fallback;
    jsi::Value v = prompt.getProperty(rt, name);
    if (!v.isString()) return fallback;
    return v.asString(rt).utf8(rt);
  };

  auto getBool = [&](const char *name, bool fallback) -> bool {
    if (!prompt.hasProperty(rt, name)) return fallback;
    jsi::Value v = prompt.getProperty(rt, name);
    if (!v.isBool()) return fallback;
    return v.getBool();
  };

  options.title = getString("title", options.title);
  options.subtitle = getString("subtitle", options.subtitle);
  options.negativeButtonText = getString("negativeButtonText", options.negativeButtonText);
  options.allowDeviceCredential = getBool("allowDeviceCredential", options.allowDeviceCredential);
  options.allowBiometricWeak = getBool("allowBiometricWeak", options.allowBiometricWeak);

  return options;
}

void install(
    jsi::Runtime &rt,
    std::function<void(const char *, const char *, bool, BiometricPromptOptions)> setFn,
    std::function<std::string(const char *, bool, BiometricPromptOptions)> getFn,
    std::function<void(const char *, bool, BiometricPromptOptions)> delFn) {

  _set = setFn;
  _get = getFn;
  _del = delFn;

  auto set = HOSTFN("set", 1) {
    auto res = jsi::Object(rt);

    if (const char *paramsError = validateParams(rt, args, count, true)) {
      res.setProperty(rt, "error", paramsError);
      return res;
    }

    jsi::Object params = args[0].asObject(rt);

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);
    std::string val = params.getProperty(rt, "value").asString(rt).utf8(rt);

    bool withBiometrics = readWithBiometrics(rt, params);

    BiometricPromptOptions promptOptions = extractBiometricPromptOptions(rt, params);

    try {
      _set(key.c_str(), val.c_str(), withBiometrics, promptOptions);
    } catch (std::exception &e) {
      auto errorStr = jsi::String::createFromUtf8(
          rt,
          "op-s2 could not set value, error code: " + std::string(e.what()));
      res.setProperty(rt, "error", errorStr);
    }

    return res;
  });

  auto get = HOSTFN("get", 1) {
    auto res = jsi::Object(rt);

    if (const char *paramsError = validateParams(rt, args, count, false)) {
      res.setProperty(rt, "error", paramsError);
      return res;
    }

    jsi::Object params = args[0].asObject(rt);

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);

    bool withBiometrics = readWithBiometrics(rt, params);

    BiometricPromptOptions promptOptions = extractBiometricPromptOptions(rt, params);

    try {
      auto val = _get(key.c_str(), withBiometrics, promptOptions);
      if (val.empty()) {
        res.setProperty(rt, "error", "[op-s2] Item not found");
      } else {
        res.setProperty(rt, "value", val);
      }
    } catch (std::exception &e) {
      auto errorStr = jsi::String::createFromUtf8(
          rt,
          "op-s2 could not set value, error code: " + std::string(e.what()));
      res.setProperty(rt, "error", errorStr);
    }

    return res;
  });

  auto del = HOSTFN("del", 1) {

    auto res = jsi::Object(rt);

    if (const char *paramsError = validateParams(rt, args, count, false)) {
      res.setProperty(rt, "error", paramsError);
      return res;
    }

    jsi::Object params = args[0].asObject(rt);

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);

    bool withBiometrics = readWithBiometrics(rt, params);

    BiometricPromptOptions promptOptions = extractBiometricPromptOptions(rt, params);

    try {
      _del(key.c_str(), withBiometrics, promptOptions);
    } catch (std::exception &e) {
      auto errorStr = jsi::String::createFromUtf8(
          rt,
          "op-s2 could not delete value, error code: " + std::string(e.what()));
      res.setProperty(rt, "error", errorStr);
    }

    return res;
  });

  jsi::Object module = jsi::Object(rt);

  module.setProperty(rt, "set", std::move(set));
  module.setProperty(rt, "get", std::move(get));
  module.setProperty(rt, "del", std::move(del));

  rt.global().setProperty(rt, "__OPS2Proxy", std::move(module));
}
} // namespace ops2
