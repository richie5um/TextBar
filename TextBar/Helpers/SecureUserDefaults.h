//
//  SecureUserDefaults.h
//  Astro
//
//  Created by Rich Somerfield on 26/03/2012.
//  Copyright (c) 2012 AppSense. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SecureUserDefaults : NSObject {
    
    NSString* _internalServiceName;
}

-(id)objectForKey:(NSString*)key;
-(BOOL)setObject:(id)object forKey:(NSString*)key;
-(void)removeObjectForKey:(NSString*)key;
-(void)removeAll;

+(SecureUserDefaults*)standardUserDefaults;

@end