#include "bindings.h"
#import "macros.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import <dispatch/dispatch.h>

namespace ops2 {
namespace jsi = facebook::jsi;

struct BiometricPromptArgs {
  std::string title;
  std::string subtitle;
  std::string negativeButtonText;
  bool allowDeviceCredential;
  bool allowBiometricWeak;
};

// Identifies which keychain item an operation targets beyond its key.
// Empty strings mean "unset": the service falls back to the bundle identifier
// and no access group is set, which matches the behavior before these options
// existed.
struct ItemScope {
  std::string service;
  std::string accessGroup;
};

typedef enum {
  kBiometricsStateAvailable,
  kBiometricsStateNotAvailable,
  kBiometricsStateLocked
} BiometricsState;

// MARK: - Memory Hygiene Helper
static void zeroizeString(std::string &str) {
  if (!str.empty()) {
    memset(&str[0], 0, str.size());
  }
}

// Uses the byte length rather than the C string, so an embedded NUL does not
// truncate the value. Returns nil only for invalid UTF-8.
static NSString *stringToNSString(const std::string &str) {
  return [[NSString alloc] initWithBytes:str.data() length:str.size() encoding:NSUTF8StringEncoding];
}

// Reads an optional string property. Returns false when the property is
// present but neither a string nor null/undefined; `out` is left untouched
// unless a string is found.
static bool readOptionalString(jsi::Runtime &rt, const jsi::Object &obj, const char *name, std::string &out) {
  if (!obj.hasProperty(rt, name)) return true;
  jsi::Value v = obj.getProperty(rt, name);
  if (v.isNull() || v.isUndefined()) return true;
  if (!v.isString()) return false;
  out = v.asString(rt).utf8(rt);
  return true;
}

static BiometricPromptArgs extractBiometricPromptArgs(jsi::Runtime &rt, const jsi::Object &params) {
  BiometricPromptArgs args;
  args.title = "Please authenticate";
  args.subtitle = "";
  args.negativeButtonText = "Cancel";
  args.allowDeviceCredential = false;
  args.allowBiometricWeak = false;

  if (params.hasProperty(rt, "biometricPrompt")) {
    jsi::Value prop = params.getProperty(rt, "biometricPrompt");
    if (!prop.isNull() && !prop.isUndefined() && prop.isObject()) {
      jsi::Object prompt = prop.asObject(rt);

      // For `title` and `negativeButtonText`, the native side (Android
      // BiometricPrompt in particular) requires a non-empty value. Treat an
      // empty string the same as a missing property so we always fall back
      // to a safe default.
      auto getString = [&](const char *name, const std::string &fallback, bool allowEmpty = true) -> std::string {
        std::string s = fallback;
        if (!readOptionalString(rt, prompt, name, s)) return fallback;
        if (!allowEmpty && s.empty()) return fallback;
        return s;
      };

      auto getBool = [&](const char *name, bool fallback) -> bool {
        if (!prompt.hasProperty(rt, name)) return fallback;
        jsi::Value v = prompt.getProperty(rt, name);
        if (!v.isBool()) return fallback;
        return v.getBool();
      };

      args.title = getString("title", args.title, /*allowEmpty=*/false);
      args.subtitle = getString("subtitle", args.subtitle, /*allowEmpty=*/true);
      args.negativeButtonText = getString("negativeButtonText", args.negativeButtonText, /*allowEmpty=*/false);
      args.allowDeviceCredential = getBool("allowDeviceCredential", args.allowDeviceCredential);
      args.allowBiometricWeak = getBool("allowBiometricWeak", args.allowBiometricWeak);
    }
  }

  return args;
}

// Reads `service` and `accessGroup` into `scope`. Returns an error message
// when either is present with a non-string value, so a typo can't silently
// fall back to the default scope; returns an empty string otherwise.
static std::string extractItemScope(jsi::Runtime &rt, const jsi::Object &params, ItemScope &scope) {
  if (!readOptionalString(rt, params, "service", scope.service)) {
    return "service property is not a string";
  }
  if (!readOptionalString(rt, params, "accessGroup", scope.accessGroup)) {
    return "accessGroup property is not a string";
  }
  return "";
}

// MARK: - LAContext Factory
static LAContext *createLAContext(const BiometricPromptArgs &args) {
  LAContext *context = [[LAContext alloc] init];

  // iOS does not expose a native subtitle field on the LAContext prompt.
  // When the caller provides one, append it to the localizedReason so the user still sees it.
  std::string reason = args.title;
  if (!args.subtitle.empty()) {
    reason += "\n";
    reason += args.subtitle;
  }
  NSString *localizedReason = stringToNSString(reason);
  if (localizedReason.length > 0) {
    context.localizedReason = localizedReason;
  }

  NSString *cancel = stringToNSString(args.negativeButtonText);
  if (cancel.length > 0) {
    context.localizedCancelTitle = cancel;
  }

  // Hide the fallback button if device credential fallback is not allowed
  if (!args.allowDeviceCredential) {
    context.localizedFallbackTitle = @"";
  }

  return context;
}

BiometricsState getBiometricsState(bool allowDeviceCredential) {
  LAContext *myContext = [[LAContext alloc] init];
  NSError *authError = nil;

  // When the caller accepts the device passcode as a fallback, switch to the
  // "biometrics OR passcode" policy so users without enrolled biometrics can
  // still authenticate via the keychain.
  LAPolicy policy = allowDeviceCredential
      ? LAPolicyDeviceOwnerAuthentication
      : LAPolicyDeviceOwnerAuthenticationWithBiometrics;

  if ([myContext canEvaluatePolicy:policy error:&authError]) {
    return kBiometricsStateAvailable;
  } else {
    if (authError.code == LAErrorBiometryLockout) {
      return kBiometricsStateLocked;
    } else {
      return kBiometricsStateNotAvailable;
    }
  }
}

SecAccessControlRef createBioSecAccessControl(bool allowDeviceCredential, bool allowBiometricWeak) {
  // `kSecAccessControlBiometryAny` matches any enrolled biometric (looser — closer to Android
  // Class 2 / WEAK). `kSecAccessControlBiometryCurrentSet` requires the current set of
  // enrolled biometrics (tighter — closer to Android Class 3 / STRONG).
  SecAccessControlCreateFlags biometryFlag = allowBiometricWeak
      ? kSecAccessControlBiometryAny
      : kSecAccessControlBiometryCurrentSet;

  SecAccessControlCreateFlags flags = allowDeviceCredential
      ? (biometryFlag | kSecAccessControlOr | kSecAccessControlDevicePasscode)
      : biometryFlag;

  return SecAccessControlCreateWithFlags(
      kCFAllocatorDefault,
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
      flags,
      nil);
}

NSMutableDictionary *get_base_entry_dict(const std::string &key, const ItemScope &scope) {
  NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
  [queryDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

  NSData *encodedIdentifier = [NSData dataWithBytes:key.data() length:key.length()];
  [queryDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
  [queryDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];

  // The bundle identifier can be nil in some test hosts; leave the service
  // unset then rather than crash on a nil dictionary value.
  NSString *service = scope.service.empty()
      ? [[NSBundle mainBundle] bundleIdentifier]
      : stringToNSString(scope.service);
  if (service != nil) {
    [queryDictionary setObject:service forKey:(__bridge id)kSecAttrService];
  }

  // Without an access group, queries (including the delete in `set`) match
  // every access group the app belongs to, as with the Keychain API itself.
  NSString *accessGroup = scope.accessGroup.empty() ? nil : stringToNSString(scope.accessGroup);
  if (accessGroup != nil) {
    [queryDictionary setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
  }

  return queryDictionary;
}

CFStringRef getAccessibilityValue(int accessibility) {
  switch (accessibility) {
    case 0: return kSecAttrAccessibleWhenUnlocked;
    case 1: return kSecAttrAccessibleAfterFirstUnlock;
    case 2: return kSecAttrAccessibleAlways;
    case 3: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly;
    case 4: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    case 5: return kSecAttrAccessibleAlwaysThisDeviceOnly;
    case 6: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    default: return kSecAttrAccessibleAfterFirstUnlock;
  }
}

// Robust deletion that removes both local and iCloud-synced items.
// When `withBiometrics` is false we tell the keychain NOT to surface any
// authentication UI — otherwise deleting an entry that was previously stored
// with biometric protection would pop the Face ID / passcode prompt even
// though the caller explicitly opted out of biometrics.
void _delete(const std::string &key, const ItemScope &scope, bool withBiometrics) {
  NSMutableDictionary *dict = get_base_entry_dict(key, scope);
  [dict setObject:(__bridge id)kSecAttrSynchronizableAny forKey:(__bridge id)kSecAttrSynchronizable];
  if (!withBiometrics) {
    [dict setObject:(__bridge id)kSecUseAuthenticationUIFail forKey:(__bridge id)kSecUseAuthenticationUI];
  }
  SecItemDelete((__bridge CFDictionaryRef)dict);
}

// Thread-safe dispatch for Keychain APIs that present authentication UI
static OSStatus performCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
  if ([NSThread isMainThread]) {
    return SecItemCopyMatching(query, result);
  }

  __block OSStatus status;
  dispatch_sync(dispatch_get_main_queue(), ^{
    status = SecItemCopyMatching(query, result);
  });
  return status;
}

std::string getSecurityErrorMessage(OSStatus status) {
  switch (status) {
    case noErr:
      return "";
    case errSecDuplicateItem:
      return "[op-s2] Could not set value, duplicate item";
    case errSecItemNotFound:
      return "[op-s2] Item not found";
    case errSecUserCanceled:
      return "[op-s2] User cancelled authentication";
    case errSecAuthFailed:
      return "[op-s2] Authentication failed";
    case errSecInteractionNotAllowed:
      return "[op-s2] User interaction not allowed";
    case errSecMissingEntitlement:
      return "[op-s2] Missing entitlement";
    default:
      return "[op-s2] Security error code: " + std::to_string(status) + ". Look up code error at https://www.osstatus.com/";
  }
}

void setSecurityError(jsi::Runtime &rt, jsi::Object &res, OSStatus status) {
  if (status != noErr) {
    std::string errorMessage = getSecurityErrorMessage(status);
    auto errorStr = jsi::String::createFromUtf8(rt, errorMessage);
    res.setProperty(rt, "error", errorStr);
  }
}

void install(jsi::Runtime &rt, std::shared_ptr<react::CallInvoker> jsCallInvoker) {

  auto set = HOSTFN("set", 1) {
    auto res = jsi::Object(rt);

    if (count < 1 || !args[0].isObject()) {
      res.setProperty(rt, "error", "Params must be an object");
      return res;
    }

    jsi::Object params = args[0].asObject(rt);

    if (!params.hasProperty(rt, "key") || !params.hasProperty(rt, "value")) {
      res.setProperty(rt, "error", "Key or Value property is missing");
      return res;
    }

    if (!params.getProperty(rt, "value").isString()) {
      res.setProperty(rt, "error", "Value property is not a string");
      return res;
    }

    std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);
    ItemScope scope;
    std::string scopeError = extractItemScope(rt, params, scope);
    if (!scopeError.empty()) {
      res.setProperty(rt, "error", jsi::String::createFromUtf8(rt, scopeError));
      return res;
    }

    std::string val = params.getProperty(rt, "value").asString(rt).utf8(rt);

    CFStringRef accessibility = kSecAttrAccessibleAfterFirstUnlock;
    if (params.hasProperty(rt, "accessibility") && params.getProperty(rt, "accessibility").isNumber()) {
      accessibility = getAccessibilityValue(static_cast<int>(params.getProperty(rt, "accessibility").asNumber()));
    }

    bool withBiometrics = false;
    if (params.hasProperty(rt, "withBiometrics")) {
      withBiometrics = params.getProperty(rt, "withBiometrics").asBool();
    }

    BiometricPromptArgs promptArgs = extractBiometricPromptArgs(rt, params);

    if (withBiometrics) {
      BiometricsState biometricsState = getBiometricsState(promptArgs.allowDeviceCredential);
      if (biometricsState == kBiometricsStateNotAvailable) {
        auto errorStr = jsi::String::createFromUtf8(rt, "Biometrics not available");
        res.setProperty(rt, "error", errorStr);
        return res;
      }
    }

    // Delete prior entries (both local and synced) to prevent errSecDuplicateItem
    _delete(key, scope, withBiometrics);

    NSMutableDictionary *dict = get_base_entry_dict(key, scope);

    if (withBiometrics) {
      SecAccessControlRef accessControl = createBioSecAccessControl(promptArgs.allowDeviceCredential, promptArgs.allowBiometricWeak);
      if (accessControl) {
        [dict setObject:(__bridge_transfer id)accessControl forKey:(__bridge id)kSecAttrAccessControl];
      }
      [dict setObject:createLAContext(promptArgs) forKey:(__bridge id)kSecUseAuthenticationContext];

      NSString *promptTitle = stringToNSString(promptArgs.title);
      if (promptTitle.length > 0) {
        [dict setObject:promptTitle forKey:(__bridge id)kSecUseOperationPrompt];
      }
    } else {
      [dict setObject:(__bridge id)accessibility forKey:(__bridge id)kSecAttrAccessible];
    }

    NSData *data = [NSData dataWithBytes:val.data() length:val.length()];
    [dict setObject:data forKey:(__bridge id)kSecValueData];

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);

    // Zeroize sensitive memory from input parameter
    zeroizeString(val);

    if (status != noErr) {
      setSecurityError(rt, res, status);
    }

    return res;
  });

  auto get = HOSTFN("get", 1) {
    if (count < 1 || !args[0].isObject()) {
      throw jsi::JSError(rt, "Params must be an object with key");
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

    BiometricPromptArgs promptArgs = extractBiometricPromptArgs(rt, params);
    ItemScope scope;
    std::string scopeError = extractItemScope(rt, params, scope);
    if (!scopeError.empty()) {
      throw jsi::JSError(rt, scopeError);
    }

    NSMutableDictionary *dict = get_base_entry_dict(key, scope);

    [dict setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [dict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

    auto res = jsi::Object(rt);

    if (withBiometrics) {
      BiometricsState biometricsState = getBiometricsState(promptArgs.allowDeviceCredential);

      if (biometricsState == kBiometricsStateNotAvailable) {
        auto errorStr = jsi::String::createFromUtf8(rt, "Biometrics not available");
        res.setProperty(rt, "error", errorStr);
        return res;
      }

      // Create and attach the fully configured LAContext
      [dict setObject:createLAContext(promptArgs) forKey:(__bridge id)kSecUseAuthenticationContext];

      NSString *promptTitle = stringToNSString(promptArgs.title);
      if (promptTitle.length > 0) {
        [dict setObject:promptTitle forKey:(__bridge id)kSecUseOperationPrompt];
      }

      SecAccessControlRef accessControl = createBioSecAccessControl(promptArgs.allowDeviceCredential, promptArgs.allowBiometricWeak);
      if (accessControl) {
        [dict setObject:(__bridge_transfer id)accessControl forKey:(__bridge id)kSecAttrAccessControl];
      }
    }

    CFDataRef dataResult = nil;
    // Execute copy matching on the Main Thread to ensure proper UI rendering for Face ID
    OSStatus status = performCopyMatching((__bridge CFDictionaryRef)dict, (CFTypeRef *)&dataResult);

    if (status == noErr) {
      NSData *result = (__bridge_transfer NSData *)dataResult;
      NSString *returnString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];

      std::string resultStr = [returnString UTF8String] ? [returnString UTF8String] : "";
      res.setProperty(rt, "value", jsi::String::createFromUtf8(rt, resultStr));

      zeroizeString(resultStr);
      return res;
    }

    setSecurityError(rt, res, status);
    return res;
  });

  auto del = HOSTFN("delete", 1) {
    if (count < 1 || !args[0].isObject()) {
      throw jsi::JSError(rt, "Params must be an object with key");
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
    
    ItemScope scope;
    std::string scopeError = extractItemScope(rt, params, scope);
    if (!scopeError.empty()) {
      throw jsi::JSError(rt, scopeError);
    }
    _delete(key, scope, withBiometrics);
    return {};
  });

  jsi::Object module = jsi::Object(rt);

  module.setProperty(rt, "set", std::move(set));
  module.setProperty(rt, "get", std::move(get));
  module.setProperty(rt, "del", std::move(del));

  rt.global().setProperty(rt, "__OPS2Proxy", std::move(module));
}

} // namespace ops2
