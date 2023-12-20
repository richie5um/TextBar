//
//  RSTextBarItemImportWindow.m
//  TextBar
//
//  Created by RichS on 27/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarItemImportWindow.h"

@implementation RSTextBarItemImportWindow

//-------------------------------------------------------------------------//
- (IBAction)actionInstall:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
}

//-------------------------------------------------------------------------//
- (IBAction)actionCancel:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
}

@end
