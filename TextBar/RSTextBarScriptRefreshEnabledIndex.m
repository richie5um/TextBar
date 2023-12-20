//
//  RSTextBarScriptRefreshEnabledIndex.m
//  TextBar
//
//  Created by RichS on 29/03/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScriptRefreshEnabledIndex.h"
#import "RSAppDelegate.h"
#import "RSTextBarItem.h"

@implementation RSTextBarScriptRefreshEnabledIndex

-(id)performDefaultImplementation {
    NSNumber* index = [self directParameter];
    
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    
    NSArray* textBarItems = [appDelegate textBarItems];
    NSUInteger enabledIndex = 0;
    for( RSTextBarItem* item in textBarItems ) {
        if (item.isEnabled) {
            if (enabledIndex == [index unsignedIntegerValue]) {
                [item refresh];
                return nil;
            }
            ++enabledIndex;
        }
    }

    return nil;
}

@end
