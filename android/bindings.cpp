#include "bindings.h"
#include "macros.h"
#include <iostream>
#include <jni.h>

namespace ops2 {
namespace jsi = facebook::jsi;

std::function<void(const char *, const char *, bool)> _set;
std::function<std::string(const char *, bool)> _get;
std::function<void(const char *, bool)> _del;

void install(jsi::Runtime &rt,
             std::function<void(const char *, const char *, bool)> setFn,
             std::function<std::string(const char *, bool)> getFn,
             std::function<void(const char *, bool)> delFn) {

  _set = setFn;
  _get = getFn;
  _del = delFn;

  auto set = HOSTFN("set", 1) {
    auto res = jsi::Object(rt);

    if (count < 1) {
      res.setProperty(rt, "error", "Params object is missing");
      return res;
    }

    if (!args[0].isObject()) {
      res.setProperty(rt, "error", "Params is not an object");
      return res;
    }

    jsi::Object params = args[0].asObject(rt);

    if (!params.hasProperty(rt, "key")) {
      res.setProperty(rt, "error", "Key property is missing");
      return res;
    }

    if (!params.hasProperty(rt, "value")) {
      res.setProperty(rt, "error", "Value property is missing");
      return res;
    }

    if (!params.getProperty(rt, "value").isString()) {
      res.setProperty(rt, "error", "Value property is not a string");
      return res;
    }

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);
    std::string val = params.getProperty(rt, "value").asString(rt).utf8(rt);

    bool withBiometrics = false;

    if (params.hasProperty(rt, "withBiometrics")) {
      withBiometrics = params.getProperty(rt, "withBiometrics").asBool();
    }

    try {
      _set(key.c_str(), val.c_str(), withBiometrics);
    } catch (std::exception &e) {
      auto errorStr = jsi::String::createFromUtf8(
          rt,
          "op-s2 could not set value, error code: " + std::string(e.what()));
      res.setProperty(rt, "error", errorStr);
    }

    return res;
  });

  auto get = HOSTFN("get", 1) {
    if (count < 1) {
      throw jsi::JSError(rt, "Params object is missing");
    }

    if (!args[0].isObject()) {
      throw jsi::JSError(rt, "Params must be an object with key and value");
    }

    jsi::Object params = args[0].asObject(rt);

    if (!params.hasProperty(rt, "key")) {
      throw jsi::JSError(rt, "key property is missing");
    }

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);

    bool withBiometrics = false;

    if (params.hasProperty(rt, "withBiometrics")) {
      withBiometrics = params.getProperty(rt, "withBiometrics").asBool();
    }

    auto res = jsi::Object(rt);

    try {
      auto val = _get(key.c_str(), withBiometrics);
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

    if (count < 1) {
      throw jsi::JSError(rt, "Params object is missing");
    }

    if (!args[0].isObject()) {
      throw jsi::JSError(rt, "Params must be an object with key and value");
    }

    jsi::Object params = args[0].asObject(rt);

    if (!params.hasProperty(rt, "key")) {
      throw jsi::JSError(rt, "key property is missing");
    }

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);

    bool withBiometrics = false;

    if (params.hasProperty(rt, "withBiometrics")) {
      withBiometrics = params.getProperty(rt, "withBiometrics").asBool();
    }

    _del(key.c_str(), withBiometrics);

    return {};
  });

  jsi::Object module = jsi::Object(rt);

  module.setProperty(rt, "set", std::move(set));
  module.setProperty(rt, "get", std::move(get));
  module.setProperty(rt, "del", std::move(del));

  rt.global().setProperty(rt, "__OPS2Proxy", std::move(module));
}
} // namespace ops2
