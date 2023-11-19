#import "OpSecureStorage.h"
#import <React/RCTBridge+Private.h>
#import <React/RCTUtils.h>
#import <ReactCommon/RCTTurboModule.h>
#import <jsi/jsi.h>
#import "bindings.h"


@implementation OpSecureStorage
RCT_EXPORT_MODULE()

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install)
{
    RCTBridge *bridge = [RCTBridge currentBridge];
    RCTCxxBridge *cxxBridge = (RCTCxxBridge *)bridge;
    if (cxxBridge == nil) {
        return @false;
    }
    
    using namespace facebook;
    
    auto jsiRuntime = (jsi::Runtime *)cxxBridge.runtime;
    if (jsiRuntime == nil) {
        return @false;
    }
    auto &runtime = *jsiRuntime;
    auto callInvoker = bridge.jsCallInvoker;
    
    
    opsecurestorage::install(runtime, callInvoker);
    
    return @true;
}


@end
