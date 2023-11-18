#import "OpSecureStorage.h"

@implementation OpSecureStorage
RCT_EXPORT_MODULE()

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_EXPORT_METHOD(multiply:(double)a
                  b:(double)b
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSNumber *result = @(opengineering_opsecurestorage::multiply(a, b));

    resolve(result);
}


@end
