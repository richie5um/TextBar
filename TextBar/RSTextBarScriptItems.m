//
//  RSTextBarScriptItems.m
//  TextBar
//
//  Created by RichS on 29/03/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScriptItems.h"
#import "RSAppDelegate.h"

@implementation RSTextBarScriptItems

-(id)performDefaultImplementation {
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    return [appDelegate textBarItems];
}

@end
