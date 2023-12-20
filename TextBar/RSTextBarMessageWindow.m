//
//  RSTextBarMessageWindow.m
//  TextBar
//
//  Created by RichS on 13/10/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarMessageWindow.h"

@implementation RSTextBarMessageWindow

//-------------------------------------------------------------------------//
- (IBAction)actionDismiss:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
}

@end
