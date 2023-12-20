//
//  Helpers.m
//  fflickit
//
//  Created by Rich Somerfield on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <IOKit/IOKitLib.h>
#import "Helpers.h"

@implementation Helpers

/////////////////////////////////////////////////////////////////////
+(void)showIconInDock:(BOOL)showIconInDock {
    
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    if (YES == showIconInDock) {
        
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    } else {
        
        TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    }
}

/////////////////////////////////////////////////////////////////////
// MIT license
+(BOOL)isLaunchAtStartup {
    
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = [Helpers itemRefInLoginItems];
    
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    
    // Release the reference if it exists.
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

/////////////////////////////////////////////////////////////////////
+(void)toggleLaunchAtStartup {
    
    // Toggle the state.
    BOOL shouldBeToggled = ![Helpers isLaunchAtStartup];
    
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItemsRef == nil) {
        return;
    }
    
    if (shouldBeToggled) {
        
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (__bridge_retained CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) {
            
            CFRelease(itemRef);
        }
        
    } else {
        
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [Helpers itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

/////////////////////////////////////////////////////////////////////
+(LSSharedFileListItemRef)itemRefInLoginItems {
    
    LSSharedFileListItemRef itemRef = nil;
    NSURL *itemUrl = nil;
    
    // Get the app's URL.
    NSURL *appUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItemsRef == nil) return nil;
    
    // Iterate over the LoginItems.
    NSArray *loginItems = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (int currentIndex = 0; currentIndex < [loginItems count]; currentIndex++) {
        // Get the current LoginItem and resolve its URL.
        LSSharedFileListItemRef currentItemRef = (__bridge_retained LSSharedFileListItemRef)[loginItems objectAtIndex:currentIndex];
        
        //        CFURLRef cfurl = (__bridge CFURLRef)itemUrl;
        
        CFErrorRef cfError;
        CFURLRef cfurl = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, &cfError);
        if (cfurl != NULL) {
            itemUrl = CFBridgingRelease(cfurl);
            //        }
            //
            //        if (LSSharedFileListItemResolve(currentItemRef, 0, &cfurl, NULL) == noErr) {
            // Compare the URLs for the current LoginItem and the app.
            if ([itemUrl isEqual:appUrl]) {
                // Save the LoginItem reference.
                itemRef = currentItemRef;
            }
        }
    }
    
    // Retain the LoginItem reference.
    if (itemRef != nil) CFRetain(itemRef);
    
    // Release the LoginItems lists.
    CFRelease(loginItemsRef);
    
    return itemRef;
}

/////////////////////////////////////////////////////////////////////
+(NSString*)getSerialNumber {
    
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    
    if (platformExpert) {
        
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
    
    return serialNumberAsNSString;
}

/////////////////////////////////////////////////////////////////////
+(NSString*)getOSVersionNumber {    
    NSDictionary *version = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *productVersion = [version objectForKey:@"ProductVersion"];
    
    return productVersion;
    
    /* RichS: Deprecated
     SInt32 versionMajor = 0;
     SInt32 versionMinor = 0;
     SInt32 versionBugFix = 0;
     
     Gestalt( gestaltSystemVersionMajor, &versionMajor );
     Gestalt( gestaltSystemVersionMinor, &versionMinor );
     Gestalt( gestaltSystemVersionBugFix, &versionBugFix );
     
     return [NSString stringWithFormat:@"%d.%d.%d", versionMajor, versionMinor, versionBugFix];
     */
}

//-------------------------------------------------------------------------//
+(NSAttributedString*)attributedStringForImage:(NSString*)imageNamed {
    NSImage *image = [[NSImage imageNamed:imageNamed] copy];
    NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:image];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setAttachmentCell:attachmentCell ];
    NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment:attachment];
    return attributedString;
}

//-------------------------------------------------------------------------//
+(NSImage*)resizeImage:(NSImage*)image newSize:(NSSize)newSize {
    NSImage *destImage = image;
    
    // If already the correct size, then just return itself
    if ( !( newSize.height == image.size.height && newSize.width == image.size.width ) ) {
        NSImage *sourceImage = image;
        [sourceImage setScalesWhenResized:YES];
        
        // Report an error if the source isn't a valid image
        if (![sourceImage isValid]) {
            NSLog(@"Invalid Image");
            destImage = nil;
        } else {
            destImage = [[NSImage alloc] initWithSize:newSize];
            [destImage lockFocus];
            [sourceImage setSize:newSize];
            
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
            [sourceImage drawAtPoint:NSZeroPoint
                            fromRect:CGRectMake(0, 0, newSize.width, newSize.height)
                           operation:NSCompositeCopy
                            fraction:1.0];
            [destImage unlockFocus];
        }
    }
    
    return destImage;
}

//-------------------------------------------------------------------------//
+(NSString*)simpleDateTime {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"y-M-d H:m:s (z)"];
    return [dateFormat stringFromDate:[NSDate date]];
}

//-------------------------------------------------------------------------//
+(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

//-------------------------------------------------------------------------//
+(void)removeObserver:(id)observer fromObject:(id)obj forKeyPath:(NSString*)keyPath {
    // Do nothing. This is a lame race condition where we can only remove if it has been added.
    // http://nshipster.com/key-value-observing/
    @try{
        [obj removeObserver:observer forKeyPath:keyPath];
    }
    @catch (NSException * __unused exception) {}
}

//-------------------------------------------------------------------------//
+(BOOL)supportsDarkMode {
    return !(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9);
}

//-------------------------------------------------------------------------//
+(BOOL)isOSGreaterThanOrEqualTo:(double)version {
    return !(floor(NSAppKitVersionNumber) <= version);
}

//-------------------------------------------------------------------------//
+(BOOL)isDarkMode {
    BOOL isDark = NO;
    if ( [Helpers supportsDarkMode] ) {
        NSDictionary *globalPersistentDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
        @try {
            NSString *interfaceStyle = [globalPersistentDomain valueForKey:@"AppleInterfaceStyle"];
            isDark = [interfaceStyle isEqualToString:@"Dark"];
        }
        @catch (NSException *exception) {
            isDark = NO;
        }
    }
    
    return isDark;
}

//-------------------------------------------------------------------------//
+(NSString*)pathToTextBarScriptPath:(NSString*)path {
    // Only replace if it starts with $HOME / ~
    path = [path stringByAbbreviatingWithTildeInPath];
    path = [path stringByReplacingOccurrencesOfString:@"~"
                                           withString:@"$HOME"
                                              options:NSAnchoredSearch
                                                range:NSMakeRange(0, path.length)];
    
    // Escape file scripts if they have spaces in the path and are not prefixed with the quote
    if (![path hasPrefix:@"'"]) {
        path = [path stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    }
    
    return path;
}

//-------------------------------------------------------------------------//
+(NSString*)pathFromTextBarScriptPath:(NSString*)path {
    // Only replace if it starts with $HOME / ~
    path = [path stringByReplacingOccurrencesOfString:@"$HOME"
                                           withString:@"~"
                                              options:NSAnchoredSearch
                                                range:NSMakeRange(0, path.length)];
    path = [path stringByExpandingTildeInPath];
    
    // UnEscape file scripts if they have escaped spaces in the path and are not prefixed with the quote
    if (![path hasPrefix:@"'"]) {
        path = [path stringByReplacingOccurrencesOfString:@"\\ " withString:@" "];
    }
    
    return path;
}

//-------------------------------------------------------------------------//
+(NSError*)enableExecutePermissionsForPath:(NSString*)path {
    // 740 = RWX:R--:---
    NSError* error = nil;
    [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions : @0740 }
                                     ofItemAtPath:path
                                            error:&error];
    
    return error;
}

//-------------------------------------------------------------------------//
+(NSString*)escapeUnescapedSpaces:(NSString*)string {
    // This is tricky as we only want to escape spaces that are not already escaped.
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\\\)?( )" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"\\\\$2"];
    return modifiedString;
}

//-------------------------------------------------------------------------//
+(NSDictionary*)getProxySettings {
    NSDictionary *proxySettings = (NSDictionary*)CFBridgingRelease(CFNetworkCopySystemProxySettings());
    NSArray *proxies = (NSArray*)CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)[NSURL URLWithString:@"http://www.google.com"], (__bridge CFDictionaryRef)proxySettings));
    NSDictionary *settings = [proxies objectAtIndex:0];
    
    NSLog(@"host=%@", [settings objectForKey:(NSString *)kCFProxyHostNameKey]);
    NSLog(@"port=%@", [settings objectForKey:(NSString *)kCFProxyPortNumberKey]);
    NSLog(@"type=%@", [settings objectForKey:(NSString *)kCFProxyTypeKey]);
    
    return @{};
}

@end
