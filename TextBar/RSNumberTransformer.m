//
//  RSNumberTransformer.m
//  TextBar
//
//  Created by RichS on 12/2/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import "RSNumberTransformer.h"

@implementation RSNumberTransformer

//-------------------------------------------------------------------------//
+ (Class)transformedValueClass {
    return [NSNumber class];
}

//-------------------------------------------------------------------------//
+ (BOOL)allowsReverseTransformation {
    return YES;
}

//-------------------------------------------------------------------------//
- (id)transformedValue:(id)value {
    if ( nil == value || ![value isKindOfClass:[NSNumber class]]) {
        return @"0";
    } else {
        return [NSString stringWithFormat:@"%@", value];
    }
}

//-------------------------------------------------------------------------//
- (id)reverseTransformedValue:(id)value {
    if ( nil == value || ![value isKindOfClass:[NSString class]]) {
        return 0;
    } else {
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [formatter numberFromString:value];
    }
}

@end
