//
//  RSTextBarScriptRefreshAll.m
//  TextBar
//
//  Created by RichS on 29/03/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScriptRefreshAll.h"
#import "RSAppDelegate.h"

@implementation RSTextBarScriptRefreshAll

-(id)performDefaultImplementation {
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    [appDelegate refreshTextBarItems];
    
    return nil;
}

@end
