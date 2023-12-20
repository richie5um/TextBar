//
//  RSTextBarScriptRefreshIndex.m
//  TextBar
//
//  Created by RichS on 29/03/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScriptRefreshIndex.h"
#import "RSAppDelegate.h"

@implementation RSTextBarScriptRefreshIndex

-(id)performDefaultImplementation {
    NSNumber* index = [self directParameter];
    
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    [appDelegate refreshTextBarItemForIndex:[index unsignedIntegerValue]];
    
    return nil;
}

@end
