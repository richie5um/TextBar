//
//  RSMenu.m
//  TextBar
//
//  Created by RichS on 12/16/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import "RSMenu.h"
#import "RSAppDelegate.h"
#import "NSImage+Extended.h"

@implementation RSMenu

//-------------------------------------------------------------------------//
- (NSMenuItem *)insertItemWithTitle:(NSString *)aString action:(SEL)aSelector keyEquivalent:(NSString *)charCode atIndex:(NSInteger)index {
    //NSLog( @"%@:%s", [self class], __FUNCTION__ );

    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    NSImage* image = [appDelegate menuImageForName:aString];
    
    NSMenuItem* menuItem = [super insertItemWithTitle:image ? @"" : aString action:aSelector keyEquivalent:charCode atIndex:index];
    
    if ( nil != image ) {
        [menuItem setImage:image];
    }
    
    return menuItem;
}

//-------------------------------------------------------------------------//
- (NSMenuItem *)addItemWithTitle:(NSString *)aString action:(SEL)aSelector keyEquivalent:(NSString *)charCode {
    // RichS: May need to override this at some point.
    //NSLog( @"%@:%s", [self class], __FUNCTION__ );
    return [super addItemWithTitle:aString action:aSelector keyEquivalent:charCode];
}

@end
