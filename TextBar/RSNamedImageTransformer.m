//
//  RSNamedImageTransformer.m
//  TextBar
//
//  Created by RichS on 11/26/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import "RSNamedImageTransformer.h"
#import "RSAppDelegate.h"

@implementation RSNamedImageTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    NSImage* image = [appDelegate itemImageForName:value];
    
    return ((value == nil || ![value isKindOfClass:[NSString class]]) ? nil : image);
}

@end
