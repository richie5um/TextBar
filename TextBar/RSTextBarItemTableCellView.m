//
//  RSTextBarItemTableCellView.m
//  TextBar
//
//  Created by RichS on 29/08/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarItemTableCellView.h"

@implementation RSTextBarItemTableCellView

-(id)init {
    if ( nil != (self = [super init])) {
        _cellTitleField.stringValue = @"Hello";
        _cellDetailField.stringValue = @"Goodbye";
    }
    return self;
}

@end
