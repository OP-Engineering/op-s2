#include "bindings.h"
#import <LocalAuthentication/LocalAuthentication.h>
//#import <React/RCTLog.h>
#import <Security/Security.h>
#import "macros.h"


namespace opsecurestorage {
    namespace jsi = facebook::jsi;

    typedef enum {
        kBiometricsStateAvailable,
        kBiometricsStateNotAvailable,
        kBiometricsStateLocked
    } BiometricsState;

    BiometricsState getBiometricsState()
    {
        LAContext *myContext = [[LAContext alloc] init];
        NSError *authError = nil;

        if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
            return kBiometricsStateAvailable;
        } else {
            if (authError.code == LAErrorBiometryLockout) {
                return kBiometricsStateLocked;
            } else {
                return kBiometricsStateNotAvailable;
            }
        }
    }

    SecAccessControlRef getBioSecAccessControl() {
        return SecAccessControlCreateWithFlags(kCFAllocatorDefault, // default allocator
                                               kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, // Require passcode to be set on device
                                               kSecAccessControlUserPresence, // checks for user presence with touchID, faceID or passcode :)
                                               nil); // Error pointer
    }

    NSMutableDictionary* newDefaultDictionary(std::string key) {
        NSMutableDictionary* queryDictionary = [[NSMutableDictionary alloc] init];
        [queryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
        NSData *encodedIdentifier = [NSData dataWithBytes:key.data() length:key.length()];
        [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
        [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
        [queryDictionary setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:(id)kSecAttrService];

        return queryDictionary;
    }

    CFStringRef getAccessibilityValue(int accessibility) {
        switch (accessibility) {
            case 0:
                return kSecAttrAccessibleWhenUnlocked;
            case 1:
                return kSecAttrAccessibleAfterFirstUnlock;
            case 2:
                return kSecAttrAccessibleAlways;
            case 3:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly;
            case 4:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
            case 5:
                return kSecAttrAccessibleAlwaysThisDeviceOnly;
            default:
                return kSecAttrAccessibleAfterFirstUnlock;
        }

        return kSecAttrAccessibleAfterFirstUnlock;
    }

    void _delete(std::string &key, bool withBiometrics) {
        NSMutableDictionary *dict = newDefaultDictionary(key);
        if(withBiometrics) {
//            [dict setObject:(__bridge id)[self getBioSecAccessControl] forKey:(id)kSecAttrAccessControl];
        }
        SecItemDelete((CFDictionaryRef)dict);
    }


    void install(jsi::Runtime &rt, std::shared_ptr<react::CallInvoker> jsCallInvoker)
    {
        auto set = HOSTFN("set", 1) {
            CFStringRef accessibility = kSecAttrAccessibleAfterFirstUnlock;
            
            if(count < 1) {
                throw jsi::JSError(rt, "Params object is missing");
            }
            
            if(!args[0].isObject()) {
                throw jsi::JSError(rt, "Params must be an object with key and value");
            }
            
            jsi::Object params = args[0].asObject(rt);
            
            if(!params.hasProperty(rt, "key")) {
                throw jsi::JSError(rt, "key property is missing");
            }
            
            if(!params.hasProperty(rt, "val")) {
                throw jsi::JSError(rt, "val property is missing");
            }
            
            std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);
            std::string val = params.getProperty(rt, "val").asString(rt).utf8(rt);
            
            if(params.hasProperty(rt, "accessibility")) {
                if(params.getProperty(rt, "accessibility").isNumber()) {
                    accessibility = getAccessibilityValue(static_cast<int>(params.getProperty(rt, "accessibility").asNumber()));
                }
            }
            
            bool withBiometrics = false;
            
            if(params.hasProperty(rt, "withBiometrics")) {
                withBiometrics = params.getProperty(rt, "withBiometrics").asBool();
            }
        
            _delete(key, withBiometrics);
        
            NSMutableDictionary *dict = newDefaultDictionary(key);
        
            // kSecAttrAccessControl is mutually excluse with kSecAttrAccessible
            // https://mobile-security.gitbook.io/mobile-security-testing-guide/ios-testing-guide/0x06f-testing-local-authentication
            if(withBiometrics) {
                [dict setObject:(__bridge_transfer id)getBioSecAccessControl() forKey:(id)kSecAttrAccessControl];
            } else {
                [dict setObject:(__bridge id)accessibility forKey:(id)kSecAttrAccessible];
            }
        
//            NSData* valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSData* data = [NSData dataWithBytes:val.data() length:val.length()];
            [dict setObject:data forKey:(id)kSecValueData];
        
            OSStatus status = SecItemAdd((CFDictionaryRef)dict, NULL);
        
            auto res = jsi::Object(rt);
            
            if (status == noErr) {
                return res;
            }
            
            auto errorStr = jsi::String::createFromUtf8(rt, "op-s2 could not set value, error code: " + std::to_string(status));
            
            res.setProperty(rt, "error", errorStr);
            
            return res;
        });
        
        auto get = HOSTFN("get", 1) {
            if(count < 1) {
                throw jsi::JSError(rt, "Params object is missing");
            }
            
            if(!args[0].isObject()) {
                throw jsi::JSError(rt, "Params must be an object with key and value");
            }
            
            jsi::Object params = args[0].asObject(rt);
            
            if(!params.hasProperty(rt, "key")) {
                throw jsi::JSError(rt, "key property is missing");
            }
            
            std::string key = params.getProperty(rt, "key").asString(rt).utf8(rt);
            
            bool withBiometrics = false;
            
            if(params.hasProperty(rt, "withBiometrics")) {
                withBiometrics = params.getProperty(rt, "withBiometrics").asBool();
            }
            
            NSMutableDictionary *dict = newDefaultDictionary(key);
        
            [dict setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
            [dict setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
            
            auto res = jsi::Object(rt);
        
            if(withBiometrics) {
                BiometricsState biometricsState = getBiometricsState();
                LAContext *authContext = [[LAContext alloc] init];
        
                // If device has no passcode/faceID/touchID then wallet-core cannot read the value from memory
                if(biometricsState == kBiometricsStateNotAvailable) {
                    auto errorStr = jsi::String::createFromUtf8(rt, "Biometrics not available");
                    
                    res.setProperty(rt, "error", errorStr);
                    
                    return res;
                }
        
                if(biometricsState == kBiometricsStateLocked) {
        
                    // TODO receiving a localized string might be necessary if this is happening on production
                    [authContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                localizedReason:@"You need to unlock your device"
                                          reply:^(BOOL success, NSError *error) {
                        if (!success) {
                            // Edge case when device might locked out after too many password attempts
                            // User has failed to authenticate, but due to this being a callback cannot interrupt upper lexical scope
                            // We should somehow prompt/tell the user that it has failed to authenticate
                            // and wallet could not be loaded
                        }
                    }];
                }
        
                [dict setObject:(__bridge id) getBioSecAccessControl() forKey:(id)kSecAttrAccessControl];
            }
        
            CFDataRef dataResult = nil;
            OSStatus status = SecItemCopyMatching((CFDictionaryRef)dict, (CFTypeRef*) &dataResult);
        
            
            if (status == noErr) {
                NSData* result = (__bridge NSData*) dataResult;
//                std::string val = std::string(static_cast<const char*>(result.bytes), result.length);
                NSString* returnString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                res.setProperty(rt, "value", [returnString UTF8String]);
                return res;
            }
        
            auto errorStr = jsi::String::createFromUtf8(rt, "op-s2 could not set value, error code: " + std::to_string(status));
            
            res.setProperty(rt, "error", errorStr);
            
            return res;
        });
        
        jsi::Object module = jsi::Object(rt);
        
        module.setProperty(rt, "set", std::move(set));
        module.setProperty(rt, "get", std::move(get));
        
        rt.global().setProperty(rt, "__OPSecureStoreProxy", std::move(module));
    }
}


//


//
//- (NSDictionary *)deleteItem:(NSString *)key options:(JS::NativeTurboSecureStorage::SpecDeleteItemOptions &)options {
//
//    [self innerDelete:key withBiometrics:options.biometricAuthentication().value()];
//
//    return @{};
//}
//
//@end
