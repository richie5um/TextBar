//
//  RSTextBarProxyOptions.h
//  TextBar
//
//  Created by RichS on 01/11/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSTextBarProxyOptions : NSObject <NSCoding>

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, strong) NSString* proxyType;
@property (nonatomic, strong) NSString* proxyServer;
@property (nonatomic, strong) NSNumber* proxyPort;
@property (nonatomic, assign) BOOL requiresAuth;
@property (nonatomic, strong) NSString* proxyUsername;
@property (nonatomic, strong) NSString* proxyPassword;
@property (nonatomic, strong) NSString* proxyBypass;

@property (nonatomic, strong, readonly) NSString* proxyString;

-(void)updateEnvironment:(NSMutableDictionary*)environment;

@end
