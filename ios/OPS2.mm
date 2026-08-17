#import "OPS2.h"
#import "bindings.h"
#import <React/RCTBridge+Private.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <ReactCommon/RCTTurboModule.h>
#import <jsi/jsi.h>

// RCTCxxBridge (the old-architecture class that exposed `.runtime`) no
// longer ships as of React Native 0.87 — old architecture was removed and
// `_bridge` is now an `RCTBridgeProxy` (an NSProxy) in bridgeless mode.
// RCTBridgeProxy implements `-(void *)runtime` directly (see
// React/Base/RCTBridgeProxy.mm), so a lightweight duck-typed protocol
// dodges the need to import either concrete, architecture-specific class.
@protocol OPS2RuntimeProvider <NSObject>
- (void *)runtime;
@end

@implementation OPS2
@synthesize bridge = _bridge;
RCT_EXPORT_MODULE()

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install) {
  if (_bridge == nil) {
    return @false;
  }

  // `_bridge` is `RCTBridgeProxy` (an NSProxy) in bridgeless mode, which
  // implements `-(void *)runtime` directly (React/Base/RCTBridgeProxy.mm;
  // confirmed present in the compiled binary via `nm`). Both
  // `-respondsToSelector:` and `-methodSignatureForSelector:` return false
  // negatives for this method on this NSProxy subclass — its forwarding
  // machinery only accounts for selectors it dynamically forwards, not the
  // ones it implements directly — so introspecting for support isn't
  // reliable here. Since old architecture is fully removed as of RN 0.87,
  // `_bridge` is always an RCTBridgeProxy; call `-runtime` directly and
  // guard with an exception handler instead, in case that ever changes.
  facebook::jsi::Runtime *jsiRuntime = nullptr;
  @try {
    id<OPS2RuntimeProvider> runtimeProvider = (id<OPS2RuntimeProvider>)_bridge;
    jsiRuntime = (facebook::jsi::Runtime *)[runtimeProvider runtime];
  } @catch (NSException *exception) {
    RCTLogError(@"[OP-S2] Failed to obtain the JSI runtime from the bridge: %@", exception);
    return @false;
  }
  if (jsiRuntime == nil) {
    return @false;
  }
  auto &runtime = *jsiRuntime;
  auto callInvoker = _bridge.jsCallInvoker;

  ops2::install(runtime, callInvoker);

  return @true;
}

@end
