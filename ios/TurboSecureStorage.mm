#import "TurboSecureStorage.h"
#import <TurboSecureStorage/TurboSecureStorage.h>
#import <React/RCTLog.h>


@interface TurboSecureStorage() <NativeTurboSecureStorageSpec>
@end

@implementation TurboSecureStorage

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params
{
    RCTLogInfo(@"TurboSecureStorage initialized");
    return std::make_shared<facebook::react::NativeTurboSecureStorageSpecJSI>(params);
}

+ (NSString *)moduleName {
    return @"TurboSecureStorage ";
}

- (NSDictionary *)setItem:(NSString *)key value:(NSString *)value {
    RCTLogInfo(@"TurboModuleSecureStorage setItem called");
    id keys[] = {};
    id objects[] = {};
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                           forKeys:keys
                                                             count:0];
    
    return dictionary;
}

@end
