#import "TurboSecureStorage.h"
#import <TurboSecureStorage/TurboSecureStorage.h>
#import <React/RCTLog.h>
#include <Security/Security.h>
#import <memory>
#import <jsi/jsi.h>


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
    NSMutableDictionary* queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
    [queryDictionary setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:(id)kSecAttrService];
    
    
    NSData* valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [queryDictionary setObject:valueData forKey:(id)kSecValueData];
    
    OSStatus status = SecItemAdd((CFDictionaryRef)queryDictionary, NULL);
    
    
    if (status != errSecSuccess)
    {
        id resKeys[] = { @"error"};
        id objects[] = { @"Could not save value" };
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                               forKeys:resKeys
                                                                 count:1];
        
        return dictionary;
    }
    
    id resKeys[] = {};
    id objects[] = {};
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                           forKeys:resKeys
                                                             count:0];
    
    return dictionary;
}

- (NSDictionary *)getItem:(NSString *)key {
    NSMutableDictionary* queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
    [queryDictionary setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:(id)kSecAttrService];
    
    [queryDictionary setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [queryDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    CFDataRef dataResult = nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)queryDictionary, (CFTypeRef*) &dataResult);
    NSString* returnString = @"";
    if (status == noErr)
    {
        NSData* result = (__bridge NSData*) dataResult;
        returnString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        RCTLogInfo(@"TurboModuleSecureStorage setItem called");
        id resKeys[] = { @"value"};
        id objects[] = { returnString };
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                               forKeys:resKeys
                                                                 count:1];
        
        return dictionary;
    }

    id resKeys[] = { @"error"};
    id objects[] = { @"Could not retrieve value" };
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                           forKeys:resKeys
                                                             count:1];
    
    return dictionary;
}

- (NSDictionary *)deleteItem:(NSString *)key {
    NSMutableDictionary* queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
    [queryDictionary setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:(id)kSecAttrService];
    

    OSStatus status = SecItemDelete((CFDictionaryRef)queryDictionary);

    if (status != errSecSuccess)
        {
        id resKeys[] = { @"error"};
        id objects[] = { @"Could not delete value" };
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                               forKeys:resKeys
                                                                 count:1];
        
        return dictionary;
        }
    
    id resKeys[] = {};
    id objects[] = {};
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                           forKeys:resKeys
                                                             count:0];
    return dictionary;
}



@end
