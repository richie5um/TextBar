//
//  NSString+Extensions.m
//  TextBar
//
//  Created by RichS on 26/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

//-------------------------------------------------------------------------//
+(BOOL)isEmpty:(NSString*)string {
    if([string length] == 0) { //string is empty or nil
        return YES;
    }
    
    if(![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

@end
