//
//  RSTextBarProxyOptions.m
//  TextBar
//
//  Created by RichS on 01/11/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarProxyOptions.h"
#import "NSString+Extensions.h"

@implementation RSTextBarProxyOptions

//-------------------------------------------------------------------------//
-(id)init {
    if ( nil != (self = [super init])) {
        self.proxyType = @"HTTP";
        self.proxyServer = @"";
        self.proxyPort = [NSNumber numberWithInteger:8080];
        self.proxyBypass = @"localhost,127.0.0.1,localaddress,.localdomain.com";
    }
    
    return self;
}

//-------------------------------------------------------------------------//
-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:[NSNumber numberWithBool:self.isEnabled] forKey:@"isEnabled"];
    [encoder encodeObject:self.proxyType forKey:@"proxyType"];
    [encoder encodeObject:self.proxyServer forKey:@"proxyServer"];
    [encoder encodeObject:self.proxyPort forKey:@"proxyPort"];
    [encoder encodeObject:[NSNumber numberWithBool:self.requiresAuth] forKey:@"requiresAuth"];
    [encoder encodeObject:self.proxyUsername forKey:@"proxyUsername"];
    [encoder encodeObject:self.proxyPassword forKey:@"proxyPassword"];
    [encoder encodeObject:self.proxyBypass forKey:@"proxyBypass"];
}

//-------------------------------------------------------------------------//
-(id)initWithCoder:(NSCoder*)decoder {
    if(self = [self init]) {
        self.isEnabled = [[decoder decodeObjectForKey:@"isEnabled"] boolValue];
        self.proxyType = [decoder decodeObjectForKey:@"proxyType"];
        self.proxyServer = [decoder decodeObjectForKey:@"proxyServer"];
        self.proxyPort = [decoder decodeObjectForKey:@"proxyPort"];
        self.requiresAuth = [[decoder decodeObjectForKey:@"requiresAuth"] boolValue];
        self.proxyUsername = [decoder decodeObjectForKey:@"proxyUsername"];
        self.proxyPassword = [decoder decodeObjectForKey:@"proxyPassword"];
        self.proxyBypass = [decoder decodeObjectForKey:@"proxyBypass"];
    }
    return self;
}

//-------------------------------------------------------------------------//
-(NSString*)proxyString {
    NSString* proxyString = @"";
    if (self.isEnabled) {
//        if (0 != [self.proxyType compare:@"HTTP"]) {
//            proxyString = [NSString stringWithFormat:@"%@://", self.proxyType];
//        }
        proxyString = [NSString stringWithFormat:@"%@%@:%@", proxyString, self.proxyServer, self.proxyPort];
    
        if (self.requiresAuth) {
            proxyString = [NSString stringWithFormat:@"%@:%@@%@", self.proxyUsername, self.proxyPassword, proxyString];
        }
    }
    
    return proxyString;
}

//-------------------------------------------------------------------------//
-(void)updateEnvironment:(NSMutableDictionary*)environment {
    NSString* proxyString = [self proxyString];
    if (![NSString isEmpty:proxyString]) {
        if ([self.proxyType hasPrefix:@"HTTP"]) {
            [environment setObject:[NSString stringWithFormat:@"http://%@", proxyString] forKey:@"http_proxy"];
        }

        if ([self.proxyType hasSuffix:@"HTTPS"]) {
            [environment setObject:[NSString stringWithFormat:@"https://%@", proxyString] forKey:@"https_proxy"];
        }
        
        if ([self.proxyType hasPrefix:@"SOCKS"]) {
            [environment setObject:[NSString stringWithFormat:@"%@://%@", self.proxyType, proxyString] forKey:@"socks_proxy"];
        }
        
        [environment setObject:self.proxyBypass forKey:@"no_proxy"];
    }
}

@end
