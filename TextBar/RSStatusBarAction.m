//
//  RSStatusBarAction.m
//  TextBar
//
//  Created by RichS on 12/2/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import "RSStatusBarAction.h"

@implementation RSStatusBarAction

//-------------------------------------------------------------------------//
+(RSStatusBarAction*)instanceWithDelegate:(id<RSStatusBarActionDelegate>)delegate andTag:(id)tag {
    return [[RSStatusBarAction alloc] initWithDelegate:delegate andTag:tag];
}

//-------------------------------------------------------------------------//
-(id)initWithDelegate:(id<RSStatusBarActionDelegate>)delegate andTag:(id)tag {
    if ( nil != (self = [super init])) {
        _delegate = delegate;
        _tag = tag;
    }
    return self;
}


//-------------------------------------------------------------------------//
- (void)statusBarAction:(id)sender {
    if ( nil != self.delegate ) {
        [self.delegate statusBarAction:sender withTag:self.tag];
    }
}

@end
