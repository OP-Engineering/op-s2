#ifdef __cplusplus
#import "op-engineering-op-secure-storage.h"
#endif

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNOpSecureStorageSpec.h"

@interface OpSecureStorage : NSObject <NativeOpSecureStorageSpec>
#else
#import <React/RCTBridgeModule.h>

@interface OpSecureStorage : NSObject <RCTBridgeModule>
#endif

@end
