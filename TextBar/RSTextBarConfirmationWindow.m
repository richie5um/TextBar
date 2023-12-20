//
//  RSTextBarConfirmationWindow.m
//  TextBar
//
//  Created by RichS on 21/12/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarConfirmationWindow.h"

@implementation RSTextBarConfirmationWindow

//-------------------------------------------------------------------------//
- (IBAction)actionNO:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
}

//-------------------------------------------------------------------------//
- (IBAction)actionYES:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
}

@end
