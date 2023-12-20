//
//  Helpers.h
//  fflickit
//
//  Created by Rich Somerfield on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helpers : NSObject {
@private
    
}

+(void)showIconInDock:(BOOL)showIconInDock;
+(BOOL)isLaunchAtStartup;
+(void)toggleLaunchAtStartup;
+(LSSharedFileListItemRef)itemRefInLoginItems;
+(NSString*)getSerialNumber;
+(NSString*)getOSVersionNumber;
+(NSAttributedString*)attributedStringForImage:(NSString*)imageNamed;
+(NSImage*)resizeImage:(NSImage*)image newSize:(NSSize)newSize;
+(NSString*)simpleDateTime;
+(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+(void)removeObserver:(id)observer fromObject:(id)obj forKeyPath:(NSString*)keyPath;
+(BOOL)supportsDarkMode;
+(BOOL)isDarkMode;
+(BOOL)isOSGreaterThanOrEqualTo:(double)version;
+(NSString*)pathToTextBarScriptPath:(NSString*)path;
+(NSString*)pathFromTextBarScriptPath:(NSString*)path;
+(NSError*)enableExecutePermissionsForPath:(NSString*)path;
+(NSString*)escapeUnescapedSpaces:(NSString*)string;
+(NSDictionary*)getProxySettings;

@end
