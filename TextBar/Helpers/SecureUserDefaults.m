//
//  SecureUserDefaults.m
//  Astro
//
//  Created by Rich Somerfield on 26/03/2012.
//  Copyright (c) 2012 AppSense. All rights reserved.
//

#import "SecureUserDefaults.h"
#import <Security/Security.h>
#import "SFHFKeychainUtils.h"

/////////////////////////////////////////////////////////////////////////////////////
static SecureUserDefaults *_sharedSecureUserDefaults;
    
/////////////////////////////////////////////////////////////////////////////////////
@interface SecureUserDefaults (PrivateMethods)

-(void)setServiceName:(NSString*)serviceName;
-(NSString*)internalKeyFromKey:(NSString*)key;
-(NSData*)searchForKeyChainCopyMatching:(NSString*)identifier;  
-(BOOL)createKeyChainValue:(NSData*)dataObject forIdentifier:(NSString*)identifier;  
-(BOOL)updateKeychainValue:(NSData*)dataObject forIdentifier:(NSString*)identifier;  
-(void)deleteKeychainValue:(NSString*)identifier;  
-(BOOL)doesKeyChainEntryExistForIdentifier:(NSString*)identifier;  
-(NSMutableDictionary*)newSearchDictionary:(NSString*)identifier;

@end

/////////////////////////////////////////////////////////////////////////////////////
@implementation SecureUserDefaults

#pragma mark - Singleton

/////////////////////////////////////////////////////////////////////////////////////
+(SecureUserDefaults*)standardUserDefaults {
    
    if( nil == _sharedSecureUserDefaults ) {
        
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            
            _sharedSecureUserDefaults = [[SecureUserDefaults alloc] init];
            [_sharedSecureUserDefaults setServiceName:[[NSBundle mainBundle] bundleIdentifier]];
        });
    }
    
    return _sharedSecureUserDefaults;
}

#pragma mark - External Methods

/////////////////////////////////////////////////////////////////////////////////////
-(NSString*)internalKeyFromKey:(NSString*)key {
    
    return [NSString stringWithFormat:@"%@:%@", _internalServiceName, key];
}

/////////////////////////////////////////////////////////////////////////////////////
-(void)setServiceName:(NSString*)serviceName {
    
    _internalServiceName = serviceName;
}

/////////////////////////////////////////////////////////////////////////////////////
-(id)objectForKey:(NSString*)key {
    
    id value = nil;
    
    NSString* internalKey = [self internalKeyFromKey:key];
    
    if ( [self doesKeyChainEntryExistForIdentifier:internalKey] ) {

        NSData* data = [self searchForKeyChainCopyMatching:internalKey];
        if ( nil != data ) {
            value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    
    return value;
}

/////////////////////////////////////////////////////////////////////////////////////
-(BOOL)setObject:(id)object forKey:(NSString*)key {
 
    BOOL returnValue = NO;
    
    NSString* internalKey = [self internalKeyFromKey:key];
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:object];

    // RichS: I'm not happy with this, but the check doesn't seem to work correctly, so hopefully this 'create' then 'update' will work.
    if ( ![self doesKeyChainEntryExistForIdentifier:internalKey] ) {
        [self createKeyChainValue:data forIdentifier:internalKey];
    }
    
    returnValue = [self updateKeychainValue:data forIdentifier:internalKey];
    
   return returnValue;
}

/////////////////////////////////////////////////////////////////////////////////////
-(void)removeObjectForKey:(NSString*)key {
    
    NSString* internalKey = [self internalKeyFromKey:key];
    
    if ( [self doesKeyChainEntryExistForIdentifier:internalKey] ) {
        [self deleteKeychainValue:internalKey];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)removeAll {
    
    NSError* error = nil;
    if ( ![SFHFKeychainUtils deleteItemForServiceName:_internalServiceName error:&error]) {
        
        if (error) {
            NSLog(@"removeAll: Error=%@",[error description]);
        }
    }
}

#pragma mark - Retrieval

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSMutableDictionary *)newSearchDictionary:(NSString*)identifier {
    
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:_internalServiceName forKey:(__bridge id)kSecAttrService];
    
    return searchDictionary;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSData*)searchForKeyChainCopyMatching:(NSString*)identifier {
    
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    CFDataRef dataRef;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef*)&dataRef);
    
    searchDictionary = nil;
    
    if (errSecSuccess == status) {
        NSData* result = (__bridge_transfer NSData*)dataRef;
        return result;
    }
    
    return nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)doesKeyChainEntryExistForIdentifier:(NSString*)identifier {
    
    if ([self searchForKeyChainCopyMatching:identifier] != nil) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Creation

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)createKeyChainValue:(NSData*)dataObject forIdentifier:(NSString*)identifier {
    
    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
    
    [dictionary setObject:dataObject forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    dictionary = nil;
    
    if(status == errSecSuccess){
        return YES;
    }
    
    return NO;
}

#pragma mark - Updating

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)updateKeychainValue:(NSData*)dataObject forIdentifier:(NSString*)identifier {
    
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    
    [updateDictionary setObject:dataObject forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary, (__bridge CFDictionaryRef)updateDictionary);
    
    searchDictionary = nil;
    updateDictionary = nil;
    
    if (status == errSecSuccess) {
        return YES;
    } else {
        return [self createKeyChainValue:dataObject forIdentifier:identifier];
    }
}

#pragma mark - Deletion

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)deleteKeychainValue:(NSString*)identifier {
    
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
    searchDictionary = nil;
}

@end
