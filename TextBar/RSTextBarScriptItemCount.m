//
//  RSTextBarScriptItemCount.m
//  TextBar
//
//  Created by RichS on 29/03/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScriptItemCount.h"
#import "RSAppDelegate.h"

@implementation RSTextBarScriptItemCount

-(id)performDefaultImplementation {
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    return [NSNumber numberWithUnsignedInteger:[[appDelegate textBarItems] count]];
}

@end
