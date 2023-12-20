//
//  RSTextBarScriptEnabledItemCount.m
//  TextBar
//
//  Created by RichS on 29/03/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScriptEnabledItemCount.h"
#import "RSAppDelegate.h"
#import "RSTextBarItem.h"

@implementation RSTextBarScriptEnabledItemCount

-(id)performDefaultImplementation {
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    
    NSArray* textBarItems = [appDelegate textBarItems];
    NSUInteger count = 0;
    for (RSTextBarItem* textBarItem in textBarItems) {
        if (textBarItem.isEnabled) {
            ++count;
        }
    }
    
    return [NSNumber numberWithUnsignedInteger:count];
}

@end
